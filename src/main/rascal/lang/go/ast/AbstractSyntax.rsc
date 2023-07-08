module lang::go::ast::AbstractSyntax

data File(loc at=|unknown:///|)
    = file(str packageName, list[Decl] decls)
    | errorFile(str err)
    ;

data Decl(loc at=|unknown:///|)
    = genDecl(DeclType declType, list[Spec] decls)
    | funDecl(str name, list[Field] receivers, Expr funType, OptionStmt body)
    ;

data Spec(loc at=|unknown:///|)
    = importSpec(OptionalName importName, BasicLiteral importPath)
    | valueSpec(list[str] names, OptionExpr valueType, list[Expr] values)
    | typeSpec(str typeName, list[Field] typeParams, Expr \type)
    | unknownSpec()
    ;

data Stmt(loc at=|unknown:///|)
    = declStmt(Decl decl)
    | emptyStmt()
    | labeledStmt(Label label, Stmt stmt)
    | exprStmt(Expr expr)
    | sendStmt(Expr channel, Expr val)
    | incDecStmt(Op op, Expr expr)
    | assignStmt(list[Expr] targets, list[Expr] values, AssignOp assignOp)    
    | goStmt(Expr expr)
    | deferStmt(Expr expr)  
    | returnStmt(list[Expr] values)
    | branchStmt(BranchType branchType, Label label)
    | blockStmt(list[Stmt] stmts)
    | ifStmt(OptionStmt initStmtOpt, Expr cond, Stmt body, OptionStmt elseStmtOpt)
    | switchStmt(OptionStmt initOpt, OptionExpr tagOpt, list[CaseClause] cases)
    | typeSwitchStmt(OptionStmt initOpt, Stmt assign, list[CaseClause] cases)    
    | selectStmt(list[CommClause] clauses)
    | forStmt(OptionStmt initStmtOpt, OptionExpr condExprOpt, OptionStmt postStmtOpt, Stmt body)    
    | rangeStmt(OptionExpr keyOpt, OptionExpr valOpt, AssignOp assignOp, Expr rangeExpr, Stmt body)
    | unknownStmt(str unknownStmt)
    ;

data Expr(loc at=|unknown:///|)
    = ident(str name)  
    | ellipsis(OptionExpr elementType)
    | basicLit(BasicLiteral literalValue)
    | funcLit(Expr funcType, Stmt body)
    | compositeLit(OptionExpr literalType, list[Expr] elts, bool incomplete)
    | selectorExpr(Expr expr, str selector)
    | indexExpr(Expr expr, Expr index)
    | indexListExpr(Expr expr, list[Expr] indexes)
    | sliceExpr(Expr expr, OptionExpr low, OptionExpr high, OptionExpr max, bool threeIndex)
    | typeAssertExpr(Expr expr, OptionExpr assertedType)
    | callExpr(Expr fun, list[Expr] args, bool hasEllipses)
    | starExpr(Expr expr)
    | unaryExpr(Expr expr, Op operator)
    | binaryExpr(Expr left, Expr right, Op operator)
    | keyValueExpr(Expr key, Expr val)
    | arrayType(OptionExpr len, Expr element)
    | structType(list[Field] fields)
    | funcType(list[Field] typeParams, list[Field] params, list[Field] results)
    | interfaceType(list[Field] methods)
    | mapType(Expr key, Expr val)
    | chanType(Expr val, bool isSend)
    | unknownExpr(str unknownExpr)    
    ;  

data Op
    = add() | sub() | mul() | quo() | rem() | and() | or() | xor()
    | shiftLeft() | shiftRight() | andNot() | logicalAnd() | logicalOr()
    | arrow() | inc() | dec() | equal() | lessThan() | greaterThan()
    | not() | notEqual() | lessThanEq() | greaterThanEq()
    | unknownOp(str unknownOp)
    ;

data AssignOp
    = addAssign() | subAssign() | mulAssign() | quoAssign() | remAssign()
    | andAssign() | orAssign() | xorAssign() | shiftLeftAssign()
    | shiftRightAssign() | andNotAssign() | defineAssign() | assign()
    | noKey()
    | unknownAssign(str unknownOp)
    ;

data BranchType
    = breakBranch()
    | continueBranch()
    | gotoBranch()
    | fallthroughBranch()
    | unknownBranch(str unknownBranch)
    ;

data DeclType
    = importDecl()
    | constDecl()
    | typeDecl()
    | varDecl()
    | unknownDecl(str unknownDecl)
    ;

data Label(loc at=|unknown:///|)
    = someLabel(str labelName)
    | noLabel()
    ;

data OptionStmt
    = someStmt(Stmt stmt)
    | noStmt()
    ;

data OptionExpr
    = someExpr(Expr expr)
    | noExpr()
    ;

data CaseClause(loc at=|unknown:///|)
    = caseClause(CaseSelector caseSelector, list[Stmt] stmts)
    | invalidCaseClause()
    ;

data CaseSelector(loc at=|unknown:///|)
    = regularCase(list[Expr] values)
    | defaultCase()
    ;

data CommClause(loc at=|unknown:///|)
    = commClause(CommSelector commSelector, list[Stmt] stmts)
    | invalidCommClause()
    ;

data CommSelector(loc at=|unknown:///|)
    = regularComm(Stmt sendOrReceive)
    | defaultComm()
    ;

data BasicLiteral(loc at=|unknown:///|)
    = literalInt(int theInt)
    | literalFloat(real theFloat)
    | literalImaginary(real theFloat, real imaginaryPart)
    | literalChar(str theChar)
    | literalString(str theString)
    | unknownLiteral(str unknownValue)
    ;

data OptionBasicLiteral
    = someLiteral(BasicLiteral literal)
    | noLiteral()
    ;

data Field(loc at=|unknown:///|)
    = field(list[str] names, OptionExpr fieldType, OptionBasicLiteral fieldTag)
    ;

data OptionalName
    = someName(str id)
    | noName()
    ;
