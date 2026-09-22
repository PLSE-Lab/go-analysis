module lang::go::core::Core

import lang::go::ast::AbstractSyntax;
import lang::go::util::Utils;
import lang::go::core::Rascal2Maude;
import util::integration::maude::RLSRunner;

import IO;

public str runProgram(str corePgm) {
    // TODO: Add functionality here
    return "";
}

public str runExpr(str coreExpr) {
    parsedExpr = parseExpr(coreExpr);
    str exprAsMaude = maudeify(parsedExpr);

    str reduce(str s, list[str]ss) = "red run(pgm(exprStmt(print(<s>)))) .\n";
    RLSResult identityPost(str s) = NoResultHandler(s);
    maudeLocation = |file:///Users/hillsma/Development/maude/maude|;
    coreGoLocation = |file:///Users/hillsma/Projects/go-analysis/core-go/core-go.maude|;

    println("Preparing to run: <reduce(exprAsMaude,[])>");
    runInfo = RLSRun(coreGoLocation, reduce, identityPost);

    r = runRLSTask(maudeLocation, runInfo, exprAsMaude);

    return "<r>";
}