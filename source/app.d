import std.stdio;
import std.process;
import std.string;
import std.file;
import std.path;
import std.datetime;
import std.conv;
import std.algorithm;

string tmp;

int proc(string[] args, string cwd)
{
	return spawnProcess(args, stdin, stdout, stderr, null, Config.none, cwd).wait != 0;
}

bool dubInstall(string folder, string git, string[] output,
	string[][] compilation = [["dub", "upgrade"], ["dub", "build", "--build=release"]])
{
	writeln("Cloning " ~ folder ~ " into ", tmp);
	if (proc(["git", "clone", "-q", git, folder], tmp) != 0)
	{
		writeln("Error while cloning " ~ folder ~ ".");
		return false;
	}
	string cwd = buildNormalizedPath(tmp, folder);
	string tag = execute(["git", "describe", "--abbrev=0", "--tags"], null,
		Config.none, size_t.max, cwd).output.strip();
	if (tag.canFind(" "))
	{
		writeln("Invalid tag in git repository.");
		return false;
	}
	writeln("Checking out ", tag);
	if (proc(["git", "checkout", "-q", tag], cwd) != 0)
	{
		writeln("Error while checking out " ~ folder ~ ".");
		return false;
	}
	writeln("Compiling...");
	foreach (args; compilation)
		if (proc(args, cwd) != 0)
		{
			writeln("Error while compiling " ~ folder ~ ".");
			return false;
		}
	foreach (bin; output)
		copy(buildNormalizedPath(cwd, bin), buildNormalizedPath("bin", bin.baseName));
	writeln("Successfully compiled " ~ folder ~ "!");
	return true;
}

bool dubInstallDCD(string folder, string git, string[] output,
	string[][] compilation = [["dub", "upgrade"], ["dub", "build", "--build=release"]])
{
	writeln("Cloning " ~ folder ~ " into ", tmp);
	if (proc(["git", "clone", "-q", git, folder], tmp) != 0)
	{
		writeln("Error while cloning " ~ folder ~ ".");
		return false;
	}
	string cwd = buildNormalizedPath(tmp, folder);
	string tag = "v0.7.5";
	if (tag.canFind(" "))
	{
		writeln("Invalid tag in git repository.");
		return false;
	}
	writeln("Checking out ", tag);
	if (proc(["git", "checkout", "-q", tag], cwd) != 0)
	{
		writeln("Error while checking out " ~ folder ~ ".");
		return false;
	}
	writeln("Compiling...");
	foreach (args; compilation)
		if (proc(args, cwd) != 0)
		{
			writeln("Error while compiling " ~ folder ~ ".");
			return false;
		}
	foreach (bin; output)
		copy(buildNormalizedPath(cwd, bin), buildNormalizedPath("bin", bin.baseName));
	writeln("Successfully compiled " ~ folder ~ "!");
	return true;
}

int main(string[] args)
{
	if (!exists("bin"))
		mkdir("bin");
	if (isFile("bin"))
	{
		writeln("Could not initialize, bin is a file!");
		writeln("Please delete bin!");
		return 1;
	}

	tmp = buildNormalizedPath(tempDir, "workspaced-install-" ~ Clock.currStdTime().to!string);
	mkdirRecurse(tmp);
	scope (exit)
		rmdirRecurse(tmp);

	writeln("Welcome to the workspace-d installation guide.");
	writeln("Make sure, you have dmd, dub and git installed.");
	writeln();
	string selection;
	if (args.length > 1)
		selection = args[1];
	else
	{
		writeln("Which external components do you want to install?");
		writeln("[1] DCD - auto completion");
		writeln("[2] DScanner - code linting");
		writeln("[3] dfmt - code formatting");
		writeln("Enter a comma separated list of numbers");
		write("Selected [all]: ");
		selection = readln();
		if (!selection.strip().length)
			selection = "all";
	}
	string[] coms = selection.split(',');
	bool dcd, dscanner, dfmt;
	foreach (com; coms)
	{
		com = com.strip().toLower();
		if (com == "")
			continue;
		switch (com)
		{
		case "1":
			dcd = true;
			break;
		case "2":
			dscanner = true;
			break;
		case "3":
			dfmt = true;
			break;
		case "all":
			dcd = dscanner = dfmt = true;
			break;
		default:
			writeln("Component out of range, aborting. (", com, ")");
			return 1;
		}
	}
	version (Windows)
	{
		if (!dubInstall("workspace-d",
				"https://github.com/Pure-D/workspace-d.git", [".\\workspace-d.exe"]))
			return 1;
		if (dcd && !dubInstall("DCD", "https://github.com/Hackerpilot/DCD.git",
				[".\\bin\\dcd-client.exe", ".\\bin\\dcd-server.exe"], [["git",
				"submodule", "update", "-q", "--init", "--recursive"], ["cmd", "/c",
				"build.bat"]]))
			return 1;
		if (dscanner && !dubInstall("Dscanner",
				"https://github.com/Hackerpilot/Dscanner.git", [".\\dscanner.exe"]))
			return 1;
		if (dfmt && !dubInstall("dfmt", "https://github.com/Hackerpilot/dfmt.git",
				[".\\dfmt.exe"]))
			return 1;
	}
	else
	{
		if (!dubInstall("workspace-d",
				"https://github.com/Pure-D/workspace-d.git", ["./workspace-d"]))
			return 1;
		if (dcd && !dubInstallDCD("DCD", "https://github.com/Hackerpilot/DCD.git",
				["./bin/dcd-client", "./bin/dcd-server"], [["git", "submodule",
				"update", "-q", "--init", "--recursive"], ["make", "-j2"]]))
			return 1;
		if (dscanner && !dubInstall("Dscanner",
				"https://github.com/Hackerpilot/Dscanner.git", ["./dscanner"]))
			return 1;
		if (dfmt && !dubInstall("dfmt", "https://github.com/Hackerpilot/dfmt.git",
				["./dfmt"]))
			return 1;
	}
	writeln();
	writeln("Written applications to bin/");
	writeln("Please add them to your PATH");
	return 0;
}
