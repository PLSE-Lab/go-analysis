module lang::go::ast::System

import lang::go::ast::AbstractSyntax;

data System 
	= system(map[loc fileloc, File file] files)
	| namedVersionedSystem(str name, str version, loc baseLoc, map[loc fileloc, File file] files)
	| namedSystem(str name, loc baseLoc, map[loc fileloc, File file] files)
	| locatedSystem(loc baseLoc, map[loc fileloc, File file] files)
	;

@doc { filter a system to only contain script(_), and therefore discard errscript }
public System discardErrorScripts(System s) {
	s.files = (l : s.files[l] | l <- s.files, !(s.files[l] is errorFile));
	return s;
}

public System createEmptySystem() = system( () );
public System createEmptySystem(loc l) = locatedSystem(l, ( ) );

public set[loc] errorFiles(System s) = { l | l <- s.files, s.files[l] is errorFile };
