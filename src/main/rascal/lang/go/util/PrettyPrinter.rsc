module lang::go::util::PrettyPrinter

import lang::go::ast::AbstractSyntax;

/* Expressions */
public str prettyPrint(ident(str name)) = "<name>";
public str prettyPrint(ellipsis(someExpr(e))) = "...<prettyPrint(e)>";
public str prettyPrint(ellipsis(noExpr())) = "...";
public str prettyPrint(basicLit(BasicLiteral literalValue)) = prettyPrint(literalValue);
public str prettyPrint(funcLit(Expr funcType, Stmt body)) = "";
public str prettyPrint(compositeLit(OptionExpr literalType, list[Expr] elts, bool incomplete)) = "";
public str prettyPrint(selectorExpr(Expr expr, str selector)) = "";
public str prettyPrint(indexExpr(Expr expr, Expr index)) = "";
public str prettyPrint(indexListExpr(Expr expr, list[Expr] indexes)) = "";
public str prettyPrint(sliceExpr(Expr expr, OptionExpr low, OptionExpr high, OptionExpr max, bool threeIndex)) = "";
public str prettyPrint(typeAssertExpr(Expr expr, OptionExpr assertedType)) = "";
public str prettyPrint(callExpr(Expr fun, list[Expr] args, bool hasEllipses)) = "";
public str prettyPrint(starExpr(Expr expr)) = "";
public str prettyPrint(unaryExpr(Expr expr, Op operator)) = "<prettyPrint(operator)> <prettyPrint(expr)>";
public str prettyPrint(binaryExpr(Expr left, Expr right, Op operator)) = "<prettyPrint(left)> <prettyPrint(operator)> <prettyPrint(right)>";
public str prettyPrint(keyValueExpr(Expr key, Expr val)) = "";

public str prettyPrint(arrayType(OptionExpr len, Expr element)) = "";
public str prettyPrint(structType(list[Field] fields)) = "";
public str prettyPrint(funcType(list[Field] typeParams, list[Field] params, list[Field] results)) = "";
public str prettyPrint(interfaceType(list[Field] methods)) = "";
public str prettyPrint(mapType(Expr key, Expr val)) = "";
public str prettyPrint(chanType(Expr val, ChannelDirection direction)) = "";

// data Expr(loc at=|unknown:///|)
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

/* Operators */
public str prettyPrint(add()) = "+";
public str prettyPrint(sub()) = "-";
public str prettyPrint(mul()) = "*";
public str prettyPrint(quo()) = "/";
public str prettyPrint(rem()) = "%";
public str prettyPrint(and()) = "&";
public str prettyPrint(or()) = "|";
public str prettyPrint(shiftLeft()) = "\<\<";
public str prettyPrint(shiftRight()) = "\>\>";
public str prettyPrint(andNot()) = "&^";
public str prettyPrint(logicalAnd()) = "&&";
public str prettyPrint(logicalOr()) = "||";
public str prettyPrint(arrow()) = "\<-";
public str prettyPrint(inc()) = "++";
public str prettyPrint(dec()) = "--";
public str prettyPrint(equal()) = "==";
public str prettyPrint(lessThan()) = "\<";
public str prettyPrint(greaterThan()) = "\>";
public str prettyPrint(not()) = "!";
public str prettyPrint(notEqual()) = "!=";
public str prettyPrint(lessThanEq()) = "\<=";
public str prettyPrint(greaterThanEq()) = "\>=";
public str prettyPrint(tilde()) = "~";

private set[Op] prefixOps = { not(), tilde() };

/* Assignment Operators */
public str prettyPrint(addAssign()) = "+=";
public str prettyPrint(subAssign()) = "-=";
public str prettyPrint(mulAssign()) = "*=";
public str prettyPrint(quoAssign()) = "/=";
public str prettyPrint(remAssign()) = "%=";
public str prettyPrint(andAssign()) = "&=";
public str prettyPrint(orAssign()) = "|=";
public str prettyPrint(xorAssign()) = "^=";
public str prettyPrint(shiftLeftAssign()) = "\<\<=";
public str prettyPrint(shiftRightAssign()) = "\>\>=";
public str prettyPrint(andNotAssign()) = "&^=";
public str prettyPrint(defineAssign()) = ":=";
public str prettyPrint(assign()) = "=";

/* Literals */

// TODO
// * Check literal formats to ensure they conform to Go syntax
// * We should properly escape the string literal, not just put it in quotes
// Integer literals: 0b (binary), 0o (octal), 0x (hex), also just 0 prefix
//                   for octal, can also use upper case letters B O X
// Integer literals can contain embedded _ characters like 1_234_567 to make
//   them easier to read
// Floats can also use _ and can have an exponent. This uses e for decimal and
//   p for hexidecimal floats.
// Rune literals are character literals, need list of all escaped characters
// String literals: need to escape backslashes, newlines, double quotes for regular
//   interpreted literals, can also surround with back quotes and put in anything
//   (including newlines) except another backquote

public str prettyPrint(literalInt(int theInt)) = "<theInt>";
public str prettyPrint(literalFloat(real theFloat)) = "<theFloat>";
public str prettyPrint(literalImaginary(real theFloat, real imaginaryPart)) = "<theFloat> <imaginaryPart>";
public str prettyPrint(literalChar(str theChar)) = "<theChar>";
public str prettyPrint(literalString(str theString)) = "\"<theString>\"";
