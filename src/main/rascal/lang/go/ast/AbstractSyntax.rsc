module lang::go::ast::AbstractSyntax

data File(loc at=|unknown:///|)
    = file(str packageName, list[Decl] decls, list[genDecl], list[ImportSpec] imports)
    | errorFile(str err)
    ;

data Decl(loc at=|unknown:///|)
    = genDecl(str tok) // Need to define the actual decl constructors
    | Func(str name, list[str] body);
//---------------------------------------------------------------------------------

data ImportSpec(loc at=|unknown:///|)
    = ImportSpec(str name); // Need to define the actual import specs

//---------------------------------------------------------------------------------
data Stmt(loc at=|unknown:///|)
    = emptyStmt()
    | labeledStmt(str label)
    | exprStmt(str e)
    | sendStmt(str expr1, str expr2)
    | incDecStmt(str tok, expr)
    | assignStmt(str left, str right)    
    | goStmt(str call)
    | deferStmt(str call)  
    | returnStmt(str result)
    | branchStmt(str tok, str label)
    | blockStmt(str stmts)
    | ifStmt(str ifStmt, str expr, list[str] block, str elseStmt)
    | caseClause(list[str] stmts, list[str] exprs)
    | typeSwitchstmt(str init, str assign, list[str] block)    
    | commClause(str comm, list[str] stmts)
    | selectStmt(list[str] block)
    | switchStmt(str init, str t, list[str] block)
    | forStmt(str init, str cond, str post, list[str] block)    
    | rangeStmt(str key, str val, str x, list[str] block);    // val = value

// stmts are done
// ---------------------------------------------------------------------

data Expr(loc at=|unknown:///|)
    = ident(str name)  
    | ellipsis(str elt)
    | basicLit(str val)
    | funcLit(list[str] body)
    | compositeLit(str types, list[str] elts)
    | ParenExpr(str x)
    | selectorExpr(str x)
    | indexExpr(str x, str index)
    | indexListExpr(str x, list[str] indices) 
    | sliceExpr(str x, str low, str high, str max)
    | typeAssertExpr(str x, str types)
    | callExpr(str fun, list[str] args)
    | starExpr(str x)
    | unaryExpr(str x, str tok)
    | binaryExpr(str x, str tok, str y)
    | keyValueExpr(str key, str val)
    | arrayType(str lens, str elt)
    | structType()
    | funcType()
    | interfaceType()
    | mapType(str key, str val)
    | chanType();  
