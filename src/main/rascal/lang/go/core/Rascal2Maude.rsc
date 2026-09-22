module lang::go::core::Rascal2Maude

import lang::go::ast::AbstractSyntax;

// data Op
//     = add() | sub() | mul() | quo() | rem() | and() | or() | xor()
//     | shiftLeft() | shiftRight() | andNot() | logicalAnd() | logicalOr()
//     | arrow() | inc() | dec() | equal() | lessThan() | greaterThan()
//     | not() | notEqual() | lessThanEq() | greaterThanEq() | tilde()
//     | unknownOp(str unknownOp)
//     ;

public str convertBinOp(add()) = "_+_";
public str convertBinOp(sub()) = "_-_";
public str convertBinOp(mul()) = "_*_";
public str convertBinOp(quo()) = "_/_";
public str convertBinOp(rem()) = "_%_";
public str convertBinOp(logicalAnd()) = "_&&_";
public str convertBinOp(logicalOr()) = "_||_";
public str convertBinOp(lessThan()) = "_\<_";
public str convertBinOp(lessThanEq()) = "_\<=_";
public str convertBinOp(greaterThan()) = "_\>_";
public str convertBinOp(greaterThanEq()) = "_\>=_";
public str convertBinOp(notEqual()) = "_!=_";
public str convertBinOp(equal()) = "_==_";

public str convertUnaryOp(sub()) = "-_";

public str maudeify(literalInt(int theInt)) = "#(<theInt>)";
public str maudeify(literalString(str theString)) = "s(<theString>)";

// data BasicLiteral(loc at=|unknown:///|)
//     = literalInt(int theInt)
//     | literalFloat(real theFloat)
//     | literalImaginary(real theFloat, real imaginaryPart)
//     | literalChar(str theChar)
//     | literalString(str theString)
//     | unknownLiteral(str unknownValue)
//     ;

public str maudeify(ident(str name)) 
    = "n(\'<name>)";
public str maudeify(basicLit(BasicLiteral literalValue)) 
    = maudeify(literalValue);
public str maudeify(binaryExpr(Expr left, Expr right, Op operator))
    = "<convertBinOp(operator)>(<maudeify(left)>,<maudeify(right)>)";
public str maudeify(unaryExpr(Expr expr, Op operator))
    = "<convertUnaryOp(operator)>(<maudeify(expr)>)";


// data Expr(loc at=|unknown:///|)
//     = ident(str name)  
//     | ellipsis(OptionExpr elementType)
//     | basicLit(BasicLiteral literalValue)
//     | funcLit(Expr funcType, Stmt body)
//     | compositeLit(OptionExpr literalType, list[Expr] elts, bool incomplete)
//     | selectorExpr(Expr expr, str selector)
//     | indexExpr(Expr expr, Expr index)
//     | indexListExpr(Expr expr, list[Expr] indexes)
//     | sliceExpr(Expr expr, OptionExpr low, OptionExpr high, OptionExpr max, bool threeIndex)
//     | typeAssertExpr(Expr expr, OptionExpr assertedType)
//     | callExpr(Expr fun, list[Expr] args, bool hasEllipses)
//     | starExpr(Expr expr)
//     | unaryExpr(Expr expr, Op operator)
//     | binaryExpr(Expr left, Expr right, Op operator)
//     | keyValueExpr(Expr key, Expr val)
//     | arrayType(OptionExpr len, Expr element)
//     | structType(list[Field] fields)
//     | funcType(list[Field] typeParams, list[Field] params, list[Field] results)
//     | interfaceType(list[Field] methods)
//     | mapType(Expr key, Expr val)
//     | chanType(Expr val, ChannelDirection direction)
//     | unknownExpr(str unknownExpr)    
//     ;  