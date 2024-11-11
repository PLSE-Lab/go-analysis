module lang::go::util::CLOC

import util::ShellExec;
import IO;
import String;
import List;

import lang::go::util::Utils;

data ClocResult 
	= clocResult(int files, int blankLines, int commentLines, int sourceLines)
	| noResult()
	;

@doc{
	Compute the source lines of code for a given location. This location
	could be a single file or a directory.
}
public ClocResult goLinesOfCode(loc l, loc clocPath) {
	pid = createProcess(clocPath.path, args = [l.path]);
	res = readEntireStream(pid);
	killProcess(pid);
	if(/Go\s+<n1:\d+>\s+<n2:\d+>\s+<n3:\d+>\s+<n4:\d+>/ := res) {
		return clocResult(toInt(n1), toInt(n2), toInt(n3), toInt(n4));
	} else {
		println("Odd, no Go code found at <l.path>");
		return noResult();
	}
}
