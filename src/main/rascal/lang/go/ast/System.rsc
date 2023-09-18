module lang::go::ast::System

import lang::go::ast::AbstractSyntax;

import Exception;
import Location;

data System 
	= system(map[loc fileloc, File file] files)
	| namedVersionedSystem(str name, str version, loc baseLoc, map[loc fileloc, File file] files)
	| namedSystem(str name, loc baseLoc, map[loc fileloc, File file] files)
	| locatedSystem(loc baseLoc, map[loc fileloc, File file] files)
	;

@doc{Convert a regular system into a system with a designated name and base location.}
public System addNameAndLoc(System s, str systemName, loc systemLoc) {
	return namedSystem(systemName, systemLoc, s.files);
}

@doc{Filter a system to only contain script(_), and therefore discard errscript.}
public System discardErrorScripts(System s) {
	s.files = (l : s.files[l] | l <- s.files, !(s.files[l] is errorFile));
	return s;
}

@doc{Create an empty system.}
public System createEmptySystem() = system( () );

@doc{Create an empty system with a base location.}
public System createEmptySystem(loc l) = locatedSystem(l, ( ) );

@doc{Retrieve the set of files from the system that include some sort of processing error.}
public set[loc] errorFiles(System s) = { l | l <- s.files, s.files[l] is errorFile };

@doc{
	Given a set of directory names to exclude, return a system that does not include
	any of the files within these directories. This assumes we have a system that
	includes a base location.
}
public System filterLocatedSystem(System s, set[str] dirsToExclude) {
	if (! (s has baseLoc)) {
		throw IllegalArgument(s, "The system does not include a base location");
	}

	// Check to see if the directory is one we want to exclude
	bool excludeFile(loc l) {
		while (l != s.baseLoc) {
			if (l.file in dirsToExclude) {
				return true;
			}
			l = l.parent;
		}
		return false;
	}

	newFiles = ( l : s.files[l] | l <- s.files<0>, !excludeFile(l.parent) );
	s.files = newFiles;

	return s;
}