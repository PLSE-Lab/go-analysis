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
    = ImportSpec(str name); // Need to define the actual import specs

data emptyStmt(loc at=|unknown:///|)
    = emptyStmt();

data labeledStmt(loc at=|unknown:///|)
    = labeledStmt(str label);

data exprStmt(loc at=|unknown:///|)
    = exprStmt(str e);

data sendStmt(loc at=|unknown:///|)
    = sendStmt(str expr1, str expr2);

data incDecStmt(loc at=|unknown:///|)
    = incDecStmt(str tok, expr);

data assignStmt(loc at=|unknown:///|)
    = assignStmt(str left, str right);    

data goStmt(loc at=|unknown:///|)
    = goStmt(str call);

data deferStmt(loc at=|unknown:///|)
    = deferStmt(str call);  

data returnStmt(loc at=|unknown:///|)
    = returnStmt(str result);

data branchStmt(loc at=|unknown:///|)
    = branchStmt(str tok, str label);

data blockStmt(loc at=|unknown:///|)
    = blockStmt(str stmts);

data ifStmt(loc at=|unknown:///|)
    = ifStmt(str ifStmt, str expr, list[str] block, str elseStmt);

data caseClause(loc at=|unknown:///|)
    = caseClause(list[str] stmts, list[str] exprs);

data switchStmt(loc at=|unknown:///|)
    = switchStmt(str init, str t, list[str] block); // tag is used for something so t is meant to be tag.
   
data typeSwitchstmt(loc at=|unknown:///|)
    = typeSwitchstmt(str init, str assign, list[str] block);    

data commClause(loc at=|unknown:///|)
    = commClause(str comm, list[str], stmts);

data selectStmt(loc at=|unknown:///|)
    = selectStmt(list[str] block);

data forStmt(loc at=|unknown:///|)
    = forStmt(str init, str cond, str post, list[str], block);    

data rangeStmt(loc at=|unknown:///|)
    = rangeStmt(str key, str val, str x, list[str] block);    // val = value

// stmts are done
// ---------------------------------------------------------------------

data ident(loc at=|unknown:///|)
    = ident(str name);  

data ellipsis(loc at=|unknown:///|)
    = ellipsis(str elt);

data basicLit(loc at=|unknown:///|)
    = basicLit(str val);

data funcLit(loc at=|unknown:///|)
    = funcLit(list[str] body);

data compositeLit(loc at=|unknown:///|)
    = compositeLit(str types, list[str] elts);


data ParenExpr(loc at=|unknown:///|)
    = ParenExpr(str x);

data selectorExpr(loc at=|unknown:///|)
    = selectorExpr(str x);

data indexExpr(loc at=|unknown:///|)
    = indexExpr(str x, str index);

data indexListExpr(loc at=|unknown:///|)
    = indexListExpr(str x, list[str] indices); 

data sliceExpr(loc at=|unknown:///|)
    = sliceExpr(str x, str low, str high, str max);

data typeAssertExpr(loc at=|unknown:///|)
    = typeAssertExpr(str x, str types);

data callExpr(loc at=|unknown:///|)
    = callExpr(str fun, list[str] args);

data starExpr(loc at=|unknown:///|)
    = starExpr(str x);

data unaryExpr(loc at=|unknown:///|)
    = unaryExpr(str x, str tok);

data binaryExpr(loc at=|unknown:///|)
    = binaryExpr(str x, str tok, str y);

data keyValueExpr(loc at=|unknown:///|)
    = keyValueExpr(str key, str val);

data arrayType(loc at=|unknown:///|)
    = arrayType(str lens, str elt);

data structType(loc at=|unknown:///|)
    = structType();   

data funcType(loc at=|unknown:///|)
    = funcType();      

data interfaceType(loc at=|unknown:///|)
    = interfaceType();


data mapType(loc at=|unknown:///|)
    = mapType(str key, str val);


data chanType(loc at=|unknown:///|)
    = chanType();  
