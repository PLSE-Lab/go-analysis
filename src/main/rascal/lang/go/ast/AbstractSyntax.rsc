module lang::go::ast::AbstractSyntax

data File(loc at=|unknown:///|)
    = file(str packageName, list[Func] decls, list[genDecl], list[ImportSpec] imports)
    | errorFile(str err)
    ;

data genDecl(loc at=|unknown:///|)
    = genDecl(str tok); // Need to define the actual decl constructors

data Func(loc at=|unknown:///|)
    = Func(str name, list[str] body);
//------------------------------------------------

data ImportSpec(loc at=|unknown:///|)
    = placeholderImportSpec(); // Need to define the actual import specs

