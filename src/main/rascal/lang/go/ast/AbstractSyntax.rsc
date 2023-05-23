module lang::go::ast::AbstractSyntax

data File(loc at=|unknown:///|)
    = file(str packageName, list[Decl] decls, list[ImportSpec] imports)
    | errorFile(str err)
    ;

data Decl(loc at=|unknown:///|)
    = placeholderDecl(); // Need to define the actual decl constructors

data ImportSpec(loc at=|unknown:///|)
    = placeholderImportSpec(); // Need to define the actual import specs

