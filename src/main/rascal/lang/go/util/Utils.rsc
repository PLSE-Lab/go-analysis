module lang::go::util::Utils

import lang::go::ast::AbstractSyntax;
import lang::go::ast::System;
import lang::go::config::Config;

import IO;
import ValueIO;
import String;
import DateTime;
import util::ShellExec;

@doc { 
	Log level 0 => no logging;
	Log level 1 => main logging;
	Log level 2 => debug logging;
}
public void logMessage(str message, int level) {
	if (level <= log.Level) {
		//str date = printDate(now(), "Y-MM-dd HH:mm:ss");
		//println("<date> :: <message>");
		println("<now()> :: <message>");
	}
}

public str executeGo(list[str] opts, loc cwd) {
	str goBinLoc = goLoc.path;
	logMessage("Execution options: <opts>", 2);
  	PID pid = createProcess(goBinLoc, args=opts, workingDir=cwd);
	str goOutput = readEntireStream(pid);
	str goErr = readEntireErrStream(pid);
	killProcess(pid);

	if (trim(goErr) == "" || /Fatal error/ !:= goErr) {
		return goOutput;
	}
	
	throw IO("Error calling Go: <goErr>");
}

private File parseGoFile(loc f, list[str] opts, File error) {
	loc parserDir = lang::go::config::Config::parserDir;
	str goOutput = "";
	try {
		str filePath = f.path;
		if (f.authority != "") {
			filePath = f.authority + "/" + filePath;
		}
		goOutput = executeGo(["run", (parserDir + "go2rascal.go").path, "--filePath", "<filePath>"] + opts, parserDir);
	} catch _: {
		return error; 
	}

	res = errorFile("Parser failed in unknown way");
	if (trim(goOutput) != "") {
		try { 
			logMessage("Got output <goOutput>", 2);
			res = readTextValueString(#File, goOutput);
		} catch e : {
			res = errorFile("Parser failed: <e>");
		}			
	}

	return res;
}

@doc{Load a single Go file.}
public File loadGoFile(loc l) throws AssertionFailed {
	if (!exists(l)) return errorFile("Location <l> does not exist");
	if (l.scheme notin {"file","home","project"}) return errorFile("Only file, home, and project locations are supported");
	if (!isFile(l)) return errorFile("Location <l> must be a file");

	logMessage("Loading file <l>", 2);
	
	list[str] opts = [ ];
	File res = parseGoFile(l, opts, errorFile("Could not parse file <l.path>")); 
	if (errorFile(err) := res) logMessage("Found error in file <l.path>. Error: <err>", 2);
	return res;
}