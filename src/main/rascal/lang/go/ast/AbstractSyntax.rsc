module lang::go::ast::AbstractSyntax

data File
    = file(str packageName, list[Decl] decls, list[ImportSpec] imports, loc at)
    | errorFile(str err)
    ;

data Decl
    = toDoDecl(); // Need to define the actual decl constructors

data ImportSpec
    = toDoSpec(); // Need to define the actual import specs

