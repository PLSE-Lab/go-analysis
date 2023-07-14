module lang::go::util::Utils

import lang::go::ast::AbstractSyntax;
import lang::go::ast::System;
import lang::go::config::Config;

import IO;
import ValueIO;
import String;
import DateTime;
import List;
import util::ShellExec;
import Set;

@doc { 
	Log level 0 => no logging;
	Log level 1 => main logging;
	Log level 2 => debug logging;
}
public void logMessage(str message, int level) {
	if (level <= logLevel) {
		//str date = printDate(now(), "Y-MM-dd HH:mm:ss");
		//println("<date> :: <message>");
		println("<now()> :: <message>");
	}
}

@doc{Run the binary version of the Go AST extractor}
private str executeGoBinary(list[str] opts, loc cwd) {
	str go2rascalBinLoc = (parserDir + go2rascalBin).path;
	// logMessage("Execution options: <opts>", 2);
  	PID pid = createProcess(go2rascalBinLoc, args=opts, workingDir=cwd);
	str goOutput = readEntireStream(pid);
	str goErr = readEntireErrStream(pid);
	killProcess(pid);

	if (trim(goErr) == "" || /Fatal error/ !:= goErr) {
		return goOutput;
	}
	
	throw IO("Error calling Go2Rascal binary: <goErr>");
}

@doc{Run the source version of the Go AST extractor}
private str executeGo(list[str] opts, loc cwd) {
	str goBinLoc = goLoc.path;
	// logMessage("Execution options: <opts>", 2);
  	PID pid = createProcess(goBinLoc, args=opts, workingDir=cwd);
	str goOutput = readEntireStream(pid);
	str goErr = readEntireErrStream(pid);
	killProcess(pid);

	if (trim(goErr) == "" || /Fatal error/ !:= goErr) {
		return goOutput;
	}
	
	throw IO("Error calling Go: <goErr>");
}

@doc{Parse a Go file using the Go2Rascal system and return the AST}
private File parseGoFile(loc f, list[str] opts, File error) {
	loc parserDir = lang::go::config::Config::parserDir;
	str goOutput = "";
	try {
		str filePath = f.path;
		if (f.authority != "") {
			filePath = f.authority + "/" + filePath;
		}
		if (runConverterBinary) {
			goOutput = executeGoBinary(["--filePath", "<filePath>"] + opts, parserDir);
		} else {
			goOutput = executeGo(["run", (parserDir + go2rascalSrc).path, "--filePath", "<filePath>"] + opts, parserDir);
		}
	} catch _: {
		return error; 
	}

	res = errorFile("Parser failed in unknown way");
	if (trim(goOutput) != "") {
		try { 
			// logMessage("Got output <goOutput>", 2);
			res = readTextValueString(#File, goOutput);
		} catch e : {
			res = errorFile("Parser failed: <e>");
		}			
	}

	return res;
}

@doc{Load a single Go file}
public File loadGoFile(loc l, bool addLocationAnnotations = true) throws AssertionFailed {
	if (!exists(l)) return errorFile("Location <l> does not exist");
	if (l.scheme notin {"file","home","project"}) return errorFile("Only file, home, and project locations are supported");
	if (!isFile(l)) return errorFile("Location <l> must be a file");

	logMessage("Loading file <l>", 2);
	
	list[str] opts = [ ];
	if (addLocationAnnotations) {
		opts = opts + [ "--addLocs=True"];
	} else {
		opts = opts + [ "--addLocs=False"];
	}

	File res = parseGoFile(l, opts, errorFile("Could not parse file <l.path>")); 
	if (errorFile(err) := res) logMessage("Found error in file <l.path>. Error: <err>", 2);
	return res;
}

@doc{Load all Go files at a given directory location, with options for which extensions are Go files and location annotations.}
public System loadGoFiles(loc l, bool addLocationAnnotations = true, set[str] extensions = { "go" }) throws AssertionFailed {

	int folderCounter = 0;
	int folderTotal = 0;
	
	void increaseFolderCounter() {
		folderCounter = folderCounter + 1;
	}
	void resetCounters() {
		if (folderCounter == folderTotal) { 
			folderTotal = 0;
			folderCounter = 0;
		}
	}
	void setFolderTotal(loc baseDir) {
		folderTotal = countFolders(baseDir);
	}

	public int countFolders(loc d) = (1 | it + countFolders(d+f) | str f <- listEntries(d), isDirectory(d+f));

	System loadGoFilesInternal(loc l) {
		if (l.scheme == "file" && !exists(l)) throw AssertionFailed("Location <l> does not exist");
		if (!isDirectory(l)) throw AssertionFailed("Location <l> must be a directory");

		// regex filter exlucdes test/	
		list[loc] entries = [ l + e | e <- listEntries(l)];
		list[loc] dirEntries = [ e | e <- entries, isDirectory(e)];
		list[loc] goEntries = [ e | e <- entries, e.extension in extensions, isFile(e)];

		System goFiles = createEmptySystem();
		
		increaseFolderCounter();
		if (folderTotal == 0) setFolderTotal(l);
		
		if (size(goEntries) > 0) {	
			logMessage("<((folderCounter * 100) / folderTotal)>% [<folderCounter>/<folderTotal>] Parsing <size(goEntries)> files in directory: <l>", 2);
			for (e <- goEntries) {
				try {
					File f = loadGoFile(e, addLocationAnnotations = addLocationAnnotations);
					goFiles.files[e] = f;
				} catch IO(msg) : {
					println("<msg>");
				} catch Java(cls, msg) : {
					println("<cls>:<msg>");
				}
			}
		}
		
		for (d <- dirEntries) {
			newFiles = loadGoFilesInternal(d);
			goFiles.files = goFiles.files + newFiles.files;
		}
		
		resetCounters();
			
		return goFiles;
	}

	return loadGoFilesInternal(l);
}

@doc{Try to re-parse files that did not parse correctly on an earlier run.}
public System patchSystem(System pt, bool addLocationAnnotations = true) {
	for (l <- pt.files, pt.files[l] is errorFile) {
		newAttempt = loadGoFile(l, addLocationAnnotations=addLocationAnnotations);
		if (! (newAttempt is errorFile) ) {
			pt.files[l] = newAttempt;
		}
	}
	return pt;
}

@doc{Rebuild specific files in the system.}
public System rebuildFiles(System pt, set[loc] rebuildLocs, bool addLocationAnnotations = true) {
	for (l <- rebuildLocs, l in pt.files<0>) {
		newAttempt = loadGoFile(l, addLocationAnnotations=addLocationAnnotations);
		pt.files[l] = newAttempt;
	}
	return pt;
}

@doc{Extract the ASTs for a system and serialize them.}
public void buildSystemBinary(str p, bool addLocationAnnotations = true, set[str] extensions = { "go" }) throws AssertionFailed {
	pt = loadGoFiles(systemsDir + p, addLocationAnnotations=addLocationAnnotations, extensions=extensions);
	writeBinaryValueFile(serializedDir + "parsed/<p>.pt", pt);
}

@doc{Extract the ASTs for a system with a version tag and serialize them.}
public void buildVersionedSystemBinary(str p, str v, bool addLocationAnnotations = true, set[str] extensions = { "go" }) throws AssertionFailed {
	pt = loadGoFiles(systemsDir + p, addLocationAnnotations=addLocationAnnotations, extensions=extensions);
	writeBinaryValueFile(serializedDir + "parsed/<p>-<v>.pt", pt);
}

@doc{Extract the ASTs for all systems in the system directory and serialize them.}
public void buildSystemBinaries(bool addLocationAnnotations = true, set[str] extensions = { "go" }, bool rebuildBinaries=false, set[str] toSkip={}) throws AssertionFailed {
	for (l <- systemsDir.ls, isDirectory(l)) {
		p = l.file;
		if (p notin toSkip) {
			if (!exists(serializedDir + "parsed/<p>.pt") || rebuildBinaries) {
				logMessage("Building binary for <p>", 2);
				pt = loadGoFiles(systemsDir + p, addLocationAnnotations=addLocationAnnotations, extensions=extensions);
				writeBinaryValueFile(serializedDir + "parsed/<p>.pt", pt, compression=false);
			}
		}
	}
}

@doc{Load the ASTs for a system from serialized form.}
public System loadBinary(str systemName) {
	if (exists(serializedDir + "parsed/<systemName>.pt")) {
		return readBinaryValueFile(#System, serializedDir + "parsed/<systemName>.pt");
	}
	throw IllegalArgument(systemName, "No serialized ASTs are available for system <systemName>.");
}

@doc{Load the ASTs for a system and version from serialized form.}
public System loadVersionedBinary(str systemName, str version) {
	if (exists(serializedDir + "parsed/<systemName>-<version>.pt")) {
		return readBinaryValueFile(#System, serializedDir + "parsed/<systemName>-<version>.pt");
	}
	throw IllegalArgument(systemName, "No serialized ASTs are available for system <systemName> at version <version>.");
}

@doc{Return info about all files, in all systems, that could not be loaded.}
public rel[str systemName, loc fileLoc, File errorFile] collectErrorFiles(set[str] systems = { }) {
	rel[str systemName, loc fileLoc, File errorFile] result = { };
	if (size(systems) == 0) {
		systems = getSystemNames();
	}
	for (sysName <- systems, exists(serializedDir + "parsed/<sysName>.pt")) {
		logMessage("Checking for error in system <sysName>", 2);
		pt = loadBinary(sysName);
		for (errorLoc <- errorFiles(pt)) {
			result = result + < sysName, errorLoc, pt.files[errorLoc] >;
		}
	}
	return result;
}

@doc{Try to fix files across multiple systems}
public void patchBinaries(set[str] systems = { }, bool addLocationAnnotations = true, set[str] extensions = { "go" }, bool rebuildBinaries=false, set[str] toSkip={}) throws AssertionFailed {
	if (size(systems) == 0) {
		systems = getSystemNames();
	}
	for (sysName <- systems, exists(serializedDir + "parsed/<sysName>.pt")) {
		pt = loadBinary(sysName);
		fixed = false;
		for (errorLoc <- errorFiles(pt)) {
			f = loadGoFile(errorLoc, addLocationAnnotations=addLocationAnnotations);
			if (!f is errorFile) {
				pt.files[errorLoc] = f;
				fixed = true;
			}
		}
		if (fixed) {
			logMessage("Fixed errors in <sysName>, rewriting serialized ASTs", 2);
			writeBinaryValueFile(serializedDir + "parsed/<sysName>.pt", pt, compression=false);
			fixed = false;
		}
	}
}

@doc{Get the names of all the systems in the systems directory}
public set[str] getSystemNames() = { l.file | l <- systemsDir.ls, isDirectory(l) };
