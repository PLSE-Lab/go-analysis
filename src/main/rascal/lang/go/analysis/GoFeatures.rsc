module lang::go::analysis::GoFeatures

import lang::go::ast::AbstractSyntax;
import lang::go::ast::System;
import lang::go::util::Utils;
import lang::go::config::Config;
import lang::go::util::CLOC;

import List;
import Set;
import ValueIO;

import lang::csv::IO;

public void buildCorpus(set[str] toBuild = {}, bool rebuildBinaries=false, set[str] toSkip = {}) {
    if (size(toBuild) > 0) {
        logMessage("Building <size(toBuild)> systems", 1);
        toSkip = getSystemNames() - toBuild;
    }
    buildSystemBinaries(toSkip = toSkip, rebuildBinaries = rebuildBinaries);
}

public rel[str systemName, loc fileLoc, File errorFile] corpusErrorFiles()
    = collectErrorFiles();

public rel[str systemName, loc fileName, loc errorLoc, node errorNode] corpusErrorNodes() {
    rel[str systemName, loc fileName, loc errorLoc, node errorNode] res = { };

    systemNames = getSystemNames();
    for (sname <- systemNames) {
        logMessage("Checking system <sname>", 1);
        pt = loadBinary(sname);
        rel[str systemName, loc fileName, loc errorLoc, node errorNode] forSystem = { };
        for (floc <- pt.files<0>) {
            rel[str systemName, loc fileName, loc errorLoc, node errorNode] forFile =
                { < sname, floc, n.at, n > | /n:unknownSpec() := pt.files[floc] } +
                { < sname, floc, n.at, n > | /n:unknownStmt(_) := pt.files[floc] } +
                { < sname, floc, n.at, n > | /n:unknownExpr(_) := pt.files[floc] } +
                { < sname, floc, floc, n > | /n:unknownOp(_) := pt.files[floc] } +
                { < sname, floc, floc, n > | /n:unknownAssign(_) := pt.files[floc] } +
                { < sname, floc, floc, n > | /n:unknownBranch(_) := pt.files[floc] } +
                { < sname, floc, floc, n > | /n:unknownDecl(_) := pt.files[floc] } +
                { < sname, floc, n.at, n > | /n:unknownLiteral(_) := pt.files[floc] };
            
            if (size(forFile) > 0) {
                logMessage("Found <size(forFile)> unknowns in file <floc> in system <sname>", 1);
                forSystem = forSystem + forFile;
            }
        }
        if (size(forSystem) > 0) {
            logMessage("Found <size(forSystem)> unknowns in system <sname>", 1);
            res = res + forSystem;
        }
    }

    return res;
}

@doc{Compute system features for all systems in the corpus}
public void computeCorpusFeatures() {
    for (sname <- getSystemNames()) {
        logMessage("Computing feature counts for system <sname>", 1);
        sf = computeSystemFeatures(sname);
        writeBinaryValueFile(serializedDir + "features/<sname>.fmap", sf);
    }    
}

data Features
    = features(
        DeclFeatures df, 
        SpecFeatures sf, 
        ExprFeatures ef,
        ExprFeatures tf,
        StmtFeatures stf, 
        LiteralFeatures lf, 
        OpFeatures uops, 
        OpFeatures bops,
        AssignOpFeatures aops)
    ;

public Features newFeatures(
        DeclFeatures df = emptyDeclFeatures, 
        SpecFeatures sf = emptySpecFeatures,
        ExprFeatures ef = emptyExprFeatures,
        ExprFeatures tf = emptyExprFeatures,
        StmtFeatures stf = emptyStmtFeatures,
        LiteralFeatures lf = emptyLiteralFeatures,
        OpFeatures uops = emptyOpFeatures,
        OpFeatures bops = emptyOpFeatures,
        AssignOpFeatures aops = emptyAssignOpFeatures)
    = features(df, sf, ef, tf, stf, lf, uops, bops, aops)
    ;

private Features mergeFeatures(
    features(DeclFeatures d1, SpecFeatures s1, ExprFeatures e1, ExprFeatures t1,
        StmtFeatures stf1, LiteralFeatures lf1, OpFeatures uops1, 
        OpFeatures bops1, AssignOpFeatures aops1), 
    features(DeclFeatures d2, SpecFeatures s2, ExprFeatures e2, ExprFeatures t2,
        StmtFeatures stf2, LiteralFeatures lf2, OpFeatures uops2, 
        OpFeatures bops2, AssignOpFeatures aops2))
    = features(mergeDF(d1, d2), mergeSF(s1, s2), mergeEF(e1, e2), mergeEF(t1, t2),
        mergeStF(stf1, stf2), mergeLF(lf1, lf2), mergeOF(uops1,uops2), 
        mergeOF(bops1, bops2), mergeAOF(aops1, aops2))
    ;

@doc{Counts of the occurrences of literal features}
data LiteralFeatures
    = literalFeatures(
        int intLiterals, 
        int floatLiterals, 
        int imaginaryLiterals, 
        int charLiterals, 
        int stringLiterals)
    ;

@doc{Create a new, default `LiteralFeatures` value.}
public LiteralFeatures newLiteralFeatures(
    int intLiterals = 0,
    int floatLiterals = 0,
    int imaginaryLiterals = 0,
    int charLiterals = 0,
    int stringLiterals = 0
) = literalFeatures(intLiterals, floatLiterals, imaginaryLiterals, charLiterals, stringLiterals);

private LiteralFeatures emptyLiteralFeatures = newLiteralFeatures();

@doc{Merge the counts in two `LiteralFeatures` values.}
private LiteralFeatures mergeLF(
    literalFeatures(int il1, int fl1, int iml1, int cl1, int sl1),
    literalFeatures(int il2, int fl2, int iml2, int cl2, int sl2))
    = literalFeatures(il1 + il2, fl1 + fl2, iml1 + iml2, cl1 + cl2, sl1 + sl2); 

data SpecFeatures
    = specFeatures(
        int importSpecs,
        int valueSpecs,
        int typeSpecs
    );

public SpecFeatures newSpecFeatures(
    int importSpecs = 0, 
    int valueSpecs = 0, 
    int typeSpecs = 0) = specFeatures(importSpecs, valueSpecs, typeSpecs);

private SpecFeatures emptySpecFeatures = newSpecFeatures();

private SpecFeatures mergeSF(
    specFeatures(int i1, int v1, int t1),
    specFeatures(int i2, int v2, int t2))
    = specFeatures(i1 + i2, v1 + v2, t1 + t2);

data DeclFeatures
    = declFeatures(
        int importDecls,
        int constDecls,
        int typeDecls,
        int varDecls,
        int funDecls,
        int funReceivers,
        int typeParams
    );

public DeclFeatures newDeclFeatures(
    int importDecls = 0,
    int constDecls = 0,
    int typeDecls = 0,
    int varDecls = 0,
    int funDecls = 0,
    int funReceivers = 0,
    int typeParams = 0) = declFeatures(importDecls, constDecls, typeDecls, varDecls, funDecls, funReceivers, typeParams);

private DeclFeatures emptyDeclFeatures = newDeclFeatures();

private DeclFeatures mergeDF(
    declFeatures(int i1, int c1, int t1, int v1, int f1, int p1, int tp1),
    declFeatures(int i2, int c2, int t2, int v2, int f2, int p2, int tp2))
    = declFeatures(i1 + i2, c1 + c2, t1 + t2, v1 + v2, t1 + t2, p1 + p2, tp1 + tp2);

data ExprFeatures
    = exprFeatures(
        int identExprs,
        int ellipsisExprs,
        int basicLitExprs,
        int funcLitExprs,
        int completeCompositeLitExprs,
        int incompleteCompositeLitExprs,
        int selectorExprs,
        int indexExprs,
        int indexListExprs,
        int regularSliceExprs,
        int threeIndexSliceExprs,
        int typeAssertExprs,
        int callExprs,
        int varCallExprs,
        int starExprs,
        int unaryExprs,
        int binaryExprs,
        int keyValueExprs,
        int arrayTypeExprs,
        int structTypeExprs,
        int funcTypeExprs,
        int interfaceTypeExprs,
        int mapTypeExprs,
        int sendChanTypeExprs,
        int receiveChanTypeExprs,
        int bidirectionalChanTypeExprs)
    ;

public ExprFeatures newExprFeatures(
    int identExprs = 0, int ellipsisExprs = 0, int basicLitExprs = 0, int funcLitExprs = 0,
    int completeCompositeLitExprs = 0, int incompleteCompositeLitExprs = 0, int selectorExprs = 0, 
    int indexExprs = 0, int indexListExprs = 0,
    int regularSliceExprs = 0, int threeIndexSliceExprs = 0, int typeAssertExprs = 0, int callExprs = 0, int varCallExprs = 0,
    int starExprs = 0,
    int unaryExprs = 0, int binaryExprs = 0, int keyValueExprs = 0, int arrayTypeExprs = 0,
    int structTypeExprs = 0, int funcTypeExprs = 0, int interfaceTypeExprs = 0, int mapTypeExprs = 0,
    int sendChanTypeExprs = 0, int receiveChanTypeExprs = 0, int bidirectionalChanTypeExprs = 0) 
    = exprFeatures(identExprs, ellipsisExprs, basicLitExprs, funcLitExprs, completeCompositeLitExprs,
        incompleteCompositeLitExprs, 
        selectorExprs, indexExprs,
        indexListExprs, regularSliceExprs, threeIndexSliceExprs, typeAssertExprs, callExprs, varCallExprs,
        starExprs, unaryExprs, 
        binaryExprs, keyValueExprs,
        arrayTypeExprs, structTypeExprs, funcTypeExprs, interfaceTypeExprs, mapTypeExprs, 
        sendChanTypeExprs, receiveChanTypeExprs, bidirectionalChanTypeExprs);

public ExprFeatures mergeEF(
    exprFeatures(int identExprs1, int ellipsisExprs1, int basicLitExprs1, int funcLitExprs1, int completeCompositeLitExprs1,
                 int incompleteCompositeLitExprs1,
                 int selectorExprs1, int indexExprs1, int indexListExprs1, int regularSliceExprs1, int threeIndexSliceExprs1,
                 int typeAssertExprs1,
                 int callExprs1, int varCallExprs1, int starExprs1, int unaryExprs1, int binaryExprs1, int keyValueExprs1, int arrayTypeExprs1,
                 int structTypeExprs1, int funcTypeExprs1, int interfaceTypeExprs1, int mapTypeExprs1, int sendChanTypeExprs1,
                 int receiveChanTypeExprs1, int bidirectionalChanTypeExprs1),
    exprFeatures(int identExprs2, int ellipsisExprs2, int basicLitExprs2, int funcLitExprs2, int completeCompositeLitExprs2,
                 int incompleteCompositeLitExprs2,
                 int selectorExprs2, int indexExprs2, int indexListExprs2, int regularSliceExprs2, int threeIndexSliceExprs2,
                 int typeAssertExprs2,
                 int callExprs2, int varCallExprs2, int starExprs2, int unaryExprs2, int binaryExprs2, int keyValueExprs2, int arrayTypeExprs2,
                 int structTypeExprs2, int funcTypeExprs2, int interfaceTypeExprs2, int mapTypeExprs2, int sendChanTypeExprs2,
                 int receiveChanTypeExprs2, int bidirectionalChanTypeExprs2)) =
    exprFeatures(identExprs1 + identExprs2, ellipsisExprs1 + ellipsisExprs2, basicLitExprs1 + basicLitExprs2,
                 funcLitExprs1 + funcLitExprs2, completeCompositeLitExprs1 + completeCompositeLitExprs2, 
                 incompleteCompositeLitExprs1 + incompleteCompositeLitExprs2, selectorExprs1 + selectorExprs2,
                 indexExprs1 + indexExprs2, indexListExprs1 + indexListExprs2, regularSliceExprs1 + regularSliceExprs2,
                 threeIndexSliceExprs1 + threeIndexSliceExprs2,
                 typeAssertExprs1 + typeAssertExprs2, callExprs1 + callExprs2, varCallExprs1 + varCallExprs2,
                 starExprs1 + starExprs2, 
                 unaryExprs1 + unaryExprs2, binaryExprs1 + binaryExprs2, keyValueExprs1 + keyValueExprs2,
                 arrayTypeExprs1 + arrayTypeExprs2, structTypeExprs1 + structTypeExprs2, funcTypeExprs1 + funcTypeExprs2,
                 interfaceTypeExprs1 + interfaceTypeExprs2, mapTypeExprs1 + mapTypeExprs2, sendChanTypeExprs1 + sendChanTypeExprs2,
                 receiveChanTypeExprs1 + receiveChanTypeExprs2, bidirectionalChanTypeExprs1 + bidirectionalChanTypeExprs2);

private ExprFeatures emptyExprFeatures = newExprFeatures();    

data StmtFeatures = 
    stmtFeatures(
        int declStmts,
        int emptyStmts,
        int labeledStmts,
        int exprStmts,
        int sendStmts,
        int incDecStmts,
        int assignStmts,
        int goStmts,
        int deferStmts,
        int returnStmts,
        int breakBranchStmts,
        int continueBranchStmts,
        int gotoBranchStmts,
        int fallthroughBranchStmts,
        int blockStmts,
        int ifStmts,
        int switchStmts,
        int cases,
        int typeCases,
        int typeSwitchStmts,
        int selectStmts,
        int selectClauses,
        int forStmts,
        int rangeStmts
    );

public StmtFeatures newStmtFeatures(
    int declStmts = 0,
    int emptyStmts = 0,
    int labeledStmts = 0,
    int exprStmts = 0,
    int sendStmts = 0,
    int incDecStmts = 0,
    int assignStmts = 0,
    int goStmts = 0,
    int deferStmts = 0,
    int returnStmts = 0,
    int breakBranchStmts = 0,
    int continueBranchStmts = 0,
    int gotoBranchStmts = 0,
    int fallthroughBranchStmts = 0,
    int blockStmts = 0,
    int ifStmts = 0,
    int switchStmts = 0,
    int cases = 0,
    int typeCases = 0,
    int typeSwitchStmts = 0,
    int selectStmts = 0,
    int selectClauses = 0,
    int forStmts = 0,
    int rangeStmts = 0) = stmtFeatures(
        declStmts, emptyStmts, labeledStmts, exprStmts, sendStmts, incDecStmts, assignStmts,
        goStmts, deferStmts, returnStmts, breakBranchStmts, continueBranchStmts, gotoBranchStmts,
        fallthroughBranchStmts, blockStmts, ifStmts, switchStmts, cases, typeCases,
        typeSwitchStmts, selectStmts, selectClauses, forStmts, rangeStmts);

public StmtFeatures mergeStF(
    stmtFeatures(
        int declStmts1,
        int emptyStmts1,
        int labeledStmts1,
        int exprStmts1,
        int sendStmts1,
        int incDecStmts1,
        int assignStmts1,
        int goStmts1,
        int deferStmts1,
        int returnStmts1,
        int breakBranchStmts1,
        int continueBranchStmts1,
        int gotoBranchStmts1,
        int fallthroughBranchStmts1,
        int blockStmts1,
        int ifStmts1,
        int switchStmts1,
        int cases1,
        int typeCases1,
        int typeSwitchStmts1,
        int selectStmts1,
        int selectClauses1,
        int forStmts1,
        int rangeStmts1
    ),
    stmtFeatures(
        int declStmts2,
        int emptyStmts2,
        int labeledStmts2,
        int exprStmts2,
        int sendStmts2,
        int incDecStmts2,
        int assignStmts2,
        int goStmts2,
        int deferStmts2,
        int returnStmts2,
        int breakBranchStmts2,
        int continueBranchStmts2,
        int gotoBranchStmts2,
        int fallthroughBranchStmts2,
        int blockStmts2,
        int ifStmts2,
        int switchStmts2,
        int cases2,
        int typeCases2,
        int typeSwitchStmts2,
        int selectStmts2,
        int selectClauses2,
        int forStmts2,
        int rangeStmts2
    )) = stmtFeatures(
        declStmts1 + declStmts2,
        emptyStmts1 + emptyStmts2,
        labeledStmts1 + labeledStmts2,
        exprStmts1 + exprStmts2,
        sendStmts1 + sendStmts2,
        incDecStmts1 + incDecStmts2,
        assignStmts1 + assignStmts2,
        goStmts1 + goStmts2,
        deferStmts1 + deferStmts2,
        returnStmts1 + returnStmts2,
        breakBranchStmts1 + breakBranchStmts2,
        continueBranchStmts1 + continueBranchStmts2,
        gotoBranchStmts1 + gotoBranchStmts2,
        fallthroughBranchStmts1 + fallthroughBranchStmts2,
        blockStmts1 + blockStmts2,
        ifStmts1 + ifStmts2,
        switchStmts1 + switchStmts2,
        cases1 + cases2,
        typeCases1 + typeCases2,
        typeSwitchStmts1 + typeSwitchStmts2,
        selectStmts1 + selectStmts2,
        selectClauses1 + selectClauses2,
        forStmts1 + forStmts2,
        rangeStmts1 + rangeStmts2);

private StmtFeatures emptyStmtFeatures = newStmtFeatures();

data OpFeatures
    = opFeatures(
        int addOps,
        int subOps,
        int mulOps,
        int quoOps,
        int remOps,
        int andOps,
        int orOps,
        int xorOps,
        int shiftLeftOps,
        int shiftRightOps,
        int andNotOps,
        int logicalAndOps,
        int logicalOrOps,
        int arrowOps,
        int incOps,
        int decOps,
        int equalOps,
        int lessThanOps,
        int greaterThanOps,
        int notOps,
        int notEqualOps,
        int lessThanEqOps,
        int greaterThanEqOps,
        int tildeOps);

public OpFeatures newOpFeatures(
    int addOps = 0, int subOps = 0, int mulOps = 0, int quoOps = 0, int remOps = 0, int andOps = 0,
    int orOps = 0, int xorOps = 0, int shiftLeftOps = 0, int shiftRightOps = 0, int andNotOps = 0,
    int logicalAndOps = 0, int logicalOrOps = 0, int arrowOps = 0, int incOps = 0, int decOps = 0,
    int equalOps = 0, int lessThanOps = 0, int greaterThanOps = 0, int notOps = 0, int notEqualOps = 0,
    int lessThanEqOps = 0, int greaterThanEqOps = 0, int tildeOps = 0)
    = opFeatures(addOps, subOps, mulOps, quoOps, remOps, andOps, orOps, xorOps, shiftLeftOps, 
        shiftRightOps, andNotOps, logicalAndOps, logicalOrOps, arrowOps, incOps, decOps, equalOps,
        lessThanOps, greaterThanOps, notOps, notEqualOps, lessThanEqOps, greaterThanEqOps, tildeOps);

private OpFeatures mergeOF(
    opFeatures(
        int addOps1, int subOps1, int mulOps1, int quoOps1, int remOps1, int andOps1, int orOps1,
        int xorOps1, int shiftLeftOps1, int shiftRightOps1, int andNotOps1, int logicalAndOps1,
        int logicalOrOps1, int arrowOps1, int incOps1, int decOps1, int equalOps1, int lessThanOps1,
        int greaterThanOps1, int notOps1, int notEqualOps1, int lessThanEqOps1, int greaterThanEqOps1,
        int tildeOps1),
    opFeatures(
        int addOps2, int subOps2, int mulOps2, int quoOps2, int remOps2, int andOps2, int orOps2,
        int xorOps2, int shiftLeftOps2, int shiftRightOps2, int andNotOps2, int logicalAndOps2,
        int logicalOrOps2, int arrowOps2, int incOps2, int decOps2, int equalOps2, int lessThanOps2,
        int greaterThanOps2, int notOps2, int notEqualOps2, int lessThanEqOps2, int greaterThanEqOps2,
        int tildeOps2)) 
    = opFeatures(addOps1 + addOps2, subOps1 + subOps2, mulOps1 + mulOps2, quoOps1 + quoOps2, remOps1 + remOps2, 
        andOps1 + andOps2, orOps1 + orOps2, xorOps1 + xorOps2, shiftLeftOps1 + shiftLeftOps2, 
        shiftRightOps1 + shiftRightOps2, andNotOps1 + andNotOps2, logicalAndOps1 + logicalAndOps2, 
        logicalOrOps1 + logicalOrOps2, arrowOps1 + arrowOps2, incOps1 + incOps2, decOps1 + decOps2, 
        equalOps1 + equalOps2, lessThanOps1 + lessThanOps2, greaterThanOps1 + greaterThanOps2, 
        notOps1 + notOps2, notEqualOps1 + notEqualOps2, lessThanEqOps1 + lessThanEqOps2, 
        greaterThanEqOps1 + greaterThanEqOps2, tildeOps1 + tildeOps2);

private OpFeatures emptyOpFeatures = newOpFeatures();

data AssignOpFeatures
    = aopFeatures(
        int addAssignOps,
        int subAssignOps,
        int mulAssignOps,
        int quoAssignOps,
        int remAssignOps,
        int andAssignOps,
        int orAssignOps,
        int xorAssignOps,
        int shiftLeftAssignOps,
        int shiftRightAssignOps,
        int andNotAssignOps,
        int defineAssignOps,
        int assignOps,
        int noKeyOps);

public AssignOpFeatures newAssignOpFeatures(
    int addAssignOps = 0, int subAssignOps = 0, int mulAssignOps = 0, int quoAssignOps = 0, 
    int remAssignOps = 0, int andAssignOps = 0, int orAssignOps = 0, int xorAssignOps = 0, 
    int shiftLeftAssignOps = 0, int shiftRightAssignOps = 0, int andNotAssignOps = 0,
    int defineAssignOps = 0, int assignOps = 0, int noKeyOps = 0)
    = aopFeatures(addAssignOps, subAssignOps, mulAssignOps, quoAssignOps, remAssignOps, andAssignOps, 
        orAssignOps, xorAssignOps, shiftLeftAssignOps, shiftRightAssignOps, andNotAssignOps, defineAssignOps,
        assignOps, noKeyOps);

private AssignOpFeatures mergeAOF(
    aopFeatures(
        int addAssignOps1, int subAssignOps1, int mulAssignOps1, int quoAssignOps1, int remAssignOps1, 
        int andAssignOps1, int orAssignOps1, int xorAssignOps1, int shiftLeftAssignOps1, int shiftRightAssignOps1, 
        int andNotAssignOps1, int defineAssignOps1, int assignOps1, int noKeyOps1),
    aopFeatures(
        int addAssignOps2, int subAssignOps2, int mulAssignOps2, int quoAssignOps2, int remAssignOps2, 
        int andAssignOps2, int orAssignOps2, int xorAssignOps2, int shiftLeftAssignOps2, int shiftRightAssignOps2, 
        int andNotAssignOps2, int defineAssignOps2, int assignOps2, int noKeyOps2)) 
    = aopFeatures(addAssignOps1 + addAssignOps2, subAssignOps1 + subAssignOps2, mulAssignOps1 + mulAssignOps2, 
        quoAssignOps1 + quoAssignOps2, remAssignOps1 + remAssignOps2, andAssignOps1 + andAssignOps2, 
        orAssignOps1 + orAssignOps2, xorAssignOps1 + xorAssignOps2, shiftLeftAssignOps1 + shiftLeftAssignOps2, 
        shiftRightAssignOps1 + shiftRightAssignOps2, andNotAssignOps1 + andNotAssignOps2,
        defineAssignOps1 + defineAssignOps2, assignOps1 + assignOps2, noKeyOps1 + noKeyOps2);

private AssignOpFeatures emptyAssignOpFeatures = newAssignOpFeatures();

@doc{Store the features for an entire system.}
data SystemFeatures
    = systemFeatures(str systemName, map[loc,Features] fileFeatures);

@doc{Compute the features for the given system.}
public SystemFeatures computeSystemFeatures(str systemName) {
    pt = loadBinary(systemName);
    map[loc, Features] fileFeatures = ( );
    for (fileLoc <- pt.files<0>) {
        fileFeatures[fileLoc] = traverseFile(pt.files[fileLoc]);
    }
    return systemFeatures(systemName, fileFeatures);
}

@doc{Create a summary of all the features of all files in the system.}
public Features summarizeSystemFeatures(SystemFeatures sfeats) {
    return (
        newFeatures() 
        | mergeFeatures(it, sfeats.fileFeatures[fileLoc]) 
        | fileLoc <- sfeats.fileFeatures<0>);
}

// If the file is an error file, it has no feature counts.
public Features traverseFile(errorFile(str err)) = newFeatures();

// Traverse a file. We do not count the file itself, so we start by counting features in the
// individual decls.
public Features traverseFile(file(str _, list[Decl] decls)) {
    Features fileFeatures = newFeatures();

    // Count features in a decl. If we have a list of decls, each item in the list
    // counts as an instance of that decl type. For functions, we count the function,
    // but also count the number of parameters. Since a field can define multiple
    // parameters itself, we count the number of names for each field.
    void traverseDecl(genDecl(importDecl(), list[Spec] decls)) {
        fileFeatures.df.importDecls += size(decls);
        for (d <- decls) traverseSpec(d);
    }
    void traverseDecl(genDecl(constDecl(), list[Spec] decls)) {
        fileFeatures.df.constDecls += size(decls);
        for (d <- decls) traverseSpec(d);
    }
    void traverseDecl(genDecl(typeDecl(), list[Spec] decls)) {
        fileFeatures.df.typeDecls += size(decls);
        for (d <- decls) traverseSpec(d);
    }
    void traverseDecl(genDecl(varDecl(), list[Spec] decls)) {
        fileFeatures.df.varDecls += size(decls);
        for (d <- decls) traverseSpec(d);
    }
    void traverseDecl(funDecl(str name, list[Field] receivers, Expr funType, OptionStmt body)) {
        fileFeatures.df.funDecls += 1;
        fileFeatures.df.funReceivers += (0 | it + size(r.names) | r <- receivers);
        traverseExpr(funType);
        traverseOptionStmt(body);
    }

    // Count features in a field. We assume the caller has counted the number
    // of names if needed, so we do not count them here.
    void traverseField(field(list[str] names, OptionExpr fieldType, OptionBasicLiteral fieldTag)) {
        traverseOptionExpr(fieldType);
        traverseOptionBasicLiteral(fieldTag);
    }

    // The type version of the function above...
    void traverseTField(field(list[str] names, OptionExpr fieldType, OptionBasicLiteral fieldTag)) {
        traverseOptionTExpr(fieldType);
        traverseOptionBasicLiteral(fieldTag);
    }

    // Count features in each spec. We also count the spec itself. Note that, for value specs,
    // we count each value name as a value spec, while for each type spec, we count the number
    // of names in the type param fields to get the number of type params.
    void traverseSpec(importSpec(OptionalName importName, BasicLiteral importPath)) {
        fileFeatures.sf.importSpecs += 1;
        traverseBasicLiteral(importPath);
    }
    void traverseSpec(valueSpec(list[str] names, OptionExpr valueType, list[Expr] values)) {
        fileFeatures.sf.valueSpecs += size(names);
        traverseOptionExpr(valueType);
        for (v <- values) traverseExpr(v);
    }
    void traverseSpec(typeSpec(str typeName, list[Field] typeParams, Expr \type)) {
        fileFeatures.sf.typeSpecs += 1;
        fileFeatures.df.typeParams += (0 | it + size(r.names) | r <- typeParams);
        traverseExpr(\type);
        for (tp <- typeParams) traverseField(tp);
    }

    // We don't count the existence of optional statements, but do count
    // the statement itself. The logic for that is just handled in the code
    // that traverses the statement.
    void traverseOptionStmt(someStmt(Stmt s)) { traverseStmt(s); }
    void traverseOptionStmt(noStmt()) { ; } // Do nothing

    // Traverse statements.
    void traverseStmt(Stmt s) {
        switch(s) {
            case declStmt(Decl decl) : {
                fileFeatures.stf.declStmts += 1;
                traverseDecl(decl);
            }
            
            case emptyStmt() : {
                fileFeatures.stf.emptyStmts += 1;
            }
            
            case labeledStmt(Label _, Stmt stmt) : {
                fileFeatures.stf.labeledStmts += 1;
                traverseStmt(stmt);
                // TODO: We could differentiate between nil labels and provided labels
            }
            
            case exprStmt(Expr expr) : {
                fileFeatures.stf.exprStmts += 1;
                traverseExpr(expr);
            }
            
            case sendStmt(Expr channel, Expr val) : {
                fileFeatures.stf.sendStmts += 1;
                traverseExpr(channel);
                traverseExpr(val);
            }
            
            case incDecStmt(Op _, Expr expr) : {
                fileFeatures.stf.incDecStmts += 1;
                traverseExpr(expr);
                // TODO: Should we separate inc and dec operations?
            }
            
            case assignStmt(list[Expr] targets, list[Expr] values, AssignOp assignOp) : {
                fileFeatures.stf.assignStmts += 1;
                for (t <- targets) traverseExpr(t);
                for (v <- values) traverseExpr(v);
                traverseAssignOp(assignOp);
            }
            
            case goStmt(Expr expr) : {
                fileFeatures.stf.goStmts += 1;
                traverseExpr(expr);
            }
            
            case deferStmt(Expr expr) : {
                fileFeatures.stf.deferStmts += 1;
                traverseExpr(expr);
            }
            
            case returnStmt(list[Expr] values) : {
                fileFeatures.stf.returnStmts += 1;
                for (v <- values) traverseExpr(v);
            }
            
            case branchStmt(breakBranch(), Label label) : {
                fileFeatures.stf.breakBranchStmts += 1;
            }

            case branchStmt(continueBranch(), Label label) : {
                fileFeatures.stf.continueBranchStmts += 1;
            }

            case branchStmt(gotoBranch(), Label label) : {
                fileFeatures.stf.gotoBranchStmts += 1;
            }

            case branchStmt(fallthroughBranch(), Label label) : {
                fileFeatures.stf.fallthroughBranchStmts += 1;
            }

            case blockStmt(list[Stmt] stmts) : {
                fileFeatures.stf.blockStmts += 1;
                for (st <- stmts) traverseStmt(st);
            }
            
            case ifStmt(OptionStmt initStmtOpt, Expr cond, Stmt body, OptionStmt elseStmtOpt) : {
                fileFeatures.stf.ifStmts += 1;
                traverseOptionStmt(initStmtOpt);
                traverseExpr(cond);
                traverseStmt(body);
                traverseOptionStmt(elseStmtOpt);
            }
            
            case switchStmt(OptionStmt initOpt, OptionExpr tagOpt, list[CaseClause] cases) : {
                fileFeatures.stf.switchStmts += 1;
                fileFeatures.stf.cases += size(cases);
                traverseOptionStmt(initOpt);
                traverseOptionExpr(tagOpt);
                for (caseClause(CaseSelector caseSelector, list[Stmt] stmts) <- cases) {
                    if (regularCase(list[Expr] values) := caseSelector) {
                        for (v <- values) traverseExpr(v);
                    }
                    for (st <- stmts) traverseStmt(st);
                }
            }
            
            case typeSwitchStmt(OptionStmt initOpt, Stmt assign, list[CaseClause] cases) : {
                fileFeatures.stf.typeSwitchStmts += 1;
                fileFeatures.stf.typeCases += size(cases);
                traverseOptionStmt(initOpt);
                traverseStmt(assign);
                for (caseClause(CaseSelector caseSelector, list[Stmt] stmts) <- cases) {
                    if (regularCase(list[Expr] values) := caseSelector) {
                        for (v <- values) traverseTExpr(v);
                    }
                    for (st <- stmts) traverseStmt(st);
                }
            }
            
            case selectStmt(list[CommClause] clauses) : {
                fileFeatures.stf.selectStmts += 1;
                fileFeatures.stf.selectClauses += size(clauses);
                for (commClause(CommSelector commSelector, list[Stmt] stmts) <- clauses) {
                    if (regularComm(Stmt sendOrReceive) := commSelector) {
                        traverseStmt(sendOrReceive);
                    }
                    for (st <- stmts) traverseStmt(st);
                }
            }
            
            case forStmt(OptionStmt initStmtOpt, OptionExpr condExprOpt, OptionStmt postStmtOpt, Stmt body) : {
                fileFeatures.stf.forStmts += 1;
                traverseOptionStmt(initStmtOpt);
                traverseOptionExpr(condExprOpt);
                traverseOptionStmt(postStmtOpt);
                traverseStmt(body);
            }

            case rangeStmt(OptionExpr keyOpt, OptionExpr valOpt, AssignOp assignOp, Expr rangeExpr, Stmt body) : {
                fileFeatures.stf.rangeStmts += 1;
                traverseOptionExpr(keyOpt);
                traverseOptionExpr(valOpt);
                traverseExpr(rangeExpr);
                traverseStmt(body);
                traverseAssignOp(assignOp);
            }
        }
    }

    // Similar to how optional statements are handled, we don't count the existence
    // of an option, but do count the expression itself, which is handled by the code
    // that traverses it.
    void traverseOptionExpr(someExpr(Expr e)) { traverseExpr(e); }
    void traverseOptionExpr(noExpr()) { ; } // Do nothing

    void traverseOptionTExpr(someExpr(Expr e)) { traverseTExpr(e); }
    void traverseOptionTExpr(noExpr()) { ; } // Do nothing

    void traverseExpr(Expr e) {
        switch(e) {
            case ident(str _): {
                fileFeatures.ef.identExprs += 1;
            }

            case ellipsis(OptionExpr elementType): {
                fileFeatures.ef.ellipsisExprs +=  1;
                traverseOptionExpr(elementType);
            }

            case basicLit(BasicLiteral literalValue): {
                fileFeatures.ef.basicLitExprs += 1;
                traverseBasicLiteral(literalValue);
            }

            case funcLit(Expr funcType, Stmt body): {
                fileFeatures.ef.funcLitExprs += 1;
                traverseExpr(funcType);
                traverseStmt(body);
            }

            case compositeLit(OptionExpr literalType, list[Expr] elts, bool incomplete): {
                if (incomplete) {
                    fileFeatures.ef.incompleteCompositeLitExprs += 1;
                } else {
                    fileFeatures.ef.completeCompositeLitExprs += 1;
                }
                traverseOptionExpr(literalType);
                for (e <- elts) traverseExpr(e);
            }

            case selectorExpr(Expr expr, str selector): {
                fileFeatures.ef.selectorExprs += 1;
                traverseExpr(expr);
            }

            case indexExpr(Expr expr, Expr index): {
                fileFeatures.ef.indexExprs += 1;
                traverseExpr(expr);
                traverseExpr(index);
            }

            case indexListExpr(Expr expr, list[Expr] indexes): {
                fileFeatures.ef.indexListExprs += 1;
                traverseExpr(expr);
                for (i <- indexes) traverseExpr(i);
            }

            case sliceExpr(Expr expr, OptionExpr low, OptionExpr high, OptionExpr max, bool threeIndex): {
                if (threeIndex) {
                    fileFeatures.ef.threeIndexSliceExprs += 1;
                } else {
                    fileFeatures.ef.regularSliceExprs += 1;
                }
                traverseExpr(expr);
                traverseOptionExpr(low);
                traverseOptionExpr(high);
                traverseOptionExpr(max);
            }

            case typeAssertExpr(Expr expr, OptionExpr assertedType): {
                fileFeatures.ef.typeAssertExprs += 1;
                traverseExpr(expr);
                traverseOptionExpr(assertedType);
            }

            case callExpr(Expr fun, list[Expr] args, bool hasEllipses): {
                if (hasEllipses) {
                    fileFeatures.ef.varCallExprs += 1;
                } else {
                    fileFeatures.ef.callExprs += 1;
                }
                traverseExpr(fun);
                for (a <- args) traverseExpr(a);
            }

            case starExpr(Expr expr): {
                fileFeatures.ef.starExprs += 1;
                traverseExpr(expr);
            }

            case unaryExpr(Expr expr, Op operator): {
                fileFeatures.ef.unaryExprs += 1;
                traverseExpr(expr);
                traverseUnaryOp(operator);
            }

            case binaryExpr(Expr left, Expr right, Op operator): {
                fileFeatures.ef.binaryExprs += 1;
                traverseExpr(left);
                traverseExpr(right);
                traverseBinaryOp(operator);
            }

            case keyValueExpr(Expr key, Expr val): {
                fileFeatures.ef.keyValueExprs += 1;
                traverseExpr(key);
                traverseExpr(val);
            }

            case arrayType(OptionExpr len, Expr element): {
                fileFeatures.tf.arrayTypeExprs += 1;
                traverseOptionTExpr(len);
                traverseTExpr(element);
            }

            case structType(list[Field] fields): {
                fileFeatures.tf.structTypeExprs += 1;
                for (f <- fields) traverseTField(f);
            }

            case funcType(list[Field] typeParams, list[Field] params, list[Field] results): {
                fileFeatures.tf.funcTypeExprs += 1;
                for (tp <- typeParams) traverseTField(tp);
                for (p <- params) traverseTField(p);
                for (r <- results) traverseTField(r);
            }

            case interfaceType(list[Field] methods): {
                fileFeatures.tf.interfaceTypeExprs += 1;
                for (m <- methods) traverseTField(m);
            }

            case mapType(Expr key, Expr val): {
                fileFeatures.tf.mapTypeExprs += 1;
                traverseTExpr(key);
                traverseTExpr(val);
            }

            case chanType(Expr val, send()): {
                fileFeatures.tf.sendChanTypeExprs += 1;
                traverseTExpr(val);
            }

            case chanType(Expr val, receive()): {
                fileFeatures.tf.receiveChanTypeExprs += 1;
                traverseTExpr(val);
            }

            case chanType(Expr val, bidirectional()): {
                fileFeatures.tf.bidirectionalChanTypeExprs += 1;
                traverseTExpr(val);
            }
        }
    }

    void traverseTExpr(Expr e) {
        switch(e) {
            case ident(str _): {
                fileFeatures.tf.identExprs += 1;
            }

            case ellipsis(OptionExpr elementType): {
                fileFeatures.tf.ellipsisExprs +=  1;
                traverseOptionTExpr(elementType);
            }

            case basicLit(BasicLiteral literalValue): {
                fileFeatures.tf.basicLitExprs += 1;
                traverseBasicLiteral(literalValue);
            }

            case funcLit(Expr funcType, Stmt body): {
                fileFeatures.tf.funcLitExprs += 1;
                traverseTExpr(funcType);
                traverseStmt(body);
            }

            case compositeLit(OptionExpr literalType, list[Expr] elts, bool incomplete): {
                if (incomplete) {
                    fileFeatures.tf.incompleteCompositeLitExprs += 1;
                } else {
                    fileFeatures.tf.completeCompositeLitExprs += 1;
                }
                traverseOptionTExpr(literalType);
                for (e <- elts) traverseTExpr(e);
            }

            case selectorExpr(Expr expr, str selector): {
                fileFeatures.tf.selectorExprs += 1;
                traverseTExpr(expr);
            }

            case indexExpr(Expr expr, Expr index): {
                fileFeatures.tf.indexExprs += 1;
                traverseTExpr(expr);
                traverseTExpr(index);
            }

            case indexListExpr(Expr expr, list[Expr] indexes): {
                fileFeatures.tf.indexListExprs += 1;
                traverseTExpr(expr);
                for (i <- indexes) traverseTExpr(i);
            }

            case sliceExpr(Expr expr, OptionExpr low, OptionExpr high, OptionExpr max, bool threeIndex): {
                if (threeIndex) {
                    fileFeatures.tf.threeIndexSliceExprs += 1;
                } else {
                    fileFeatures.tf.regularSliceExprs += 1;
                }
                traverseTExpr(expr);
                traverseOptionTExpr(low);
                traverseOptionTExpr(high);
                traverseOptionTExpr(max);
            }

            case typeAssertExpr(Expr expr, OptionExpr assertedType): {
                fileFeatures.tf.typeAssertExprs += 1;
                traverseTExpr(expr);
                traverseOptionTExpr(assertedType);
            }

            case callExpr(Expr fun, list[Expr] args, bool hasEllipses): {
                if (hasEllipses) {
                    fileFeatures.tf.varCallExprs += 1;
                } else {
                    fileFeatures.tf.callExprs += 1;
                }
                traverseTExpr(fun);
                for (a <- args) traverseTExpr(a);
            }

            case starExpr(Expr expr): {
                fileFeatures.tf.starExprs += 1;
                traverseTExpr(expr);
            }

            case unaryExpr(Expr expr, Op operator): {
                fileFeatures.tf.unaryExprs += 1;
                traverseTExpr(expr);
                traverseUnaryOp(operator);
            }

            case binaryExpr(Expr left, Expr right, Op operator): {
                fileFeatures.tf.binaryExprs += 1;
                traverseTExpr(left);
                traverseTExpr(right);
                traverseBinaryOp(operator);
            }

            case keyValueExpr(Expr key, Expr val): {
                fileFeatures.tf.keyValueExprs += 1;
                traverseTExpr(key);
                traverseTExpr(val);
            }

            case arrayType(OptionExpr len, Expr element): {
                fileFeatures.tf.arrayTypeExprs += 1;
                traverseOptionTExpr(len);
                traverseTExpr(element);
            }

            case structType(list[Field] fields): {
                fileFeatures.tf.structTypeExprs += 1;
                for (f <- fields) traverseField(f);
            }

            case funcType(list[Field] typeParams, list[Field] params, list[Field] results): {
                fileFeatures.tf.funcTypeExprs += 1;
                for (tp <- typeParams) traverseField(tp);
                for (p <- params) traverseField(p);
                for (r <- results) traverseField(r);
            }

            case interfaceType(list[Field] methods): {
                fileFeatures.tf.interfaceTypeExprs += 1;
                for (m <- methods) traverseField(m);
            }

            case mapType(Expr key, Expr val): {
                fileFeatures.tf.mapTypeExprs += 1;
                traverseTExpr(key);
                traverseTExpr(val);
            }

            case chanType(Expr val, send()): {
                fileFeatures.tf.sendChanTypeExprs += 1;
                traverseTExpr(val);
            }

            case chanType(Expr val, receive()): {
                fileFeatures.tf.receiveChanTypeExprs += 1;
                traverseTExpr(val);
            }

            case chanType(Expr val, bidirectional()): {
                fileFeatures.tf.bidirectionalChanTypeExprs += 1;
                traverseTExpr(val);
            }
        }
    }

    // Similar to handling for other option types, we don't count the option,
    // but do count into in the type itself.
    void traverseOptionBasicLiteral(someLiteral(l)) { traverseBasicLiteral(l); }
    void traverseOptionBasicLiteral(noLiteral()) { ; } // Do nothing
        

    // Count the different types of basic literals. Note that we ignore
    // unknown literals, since all that we have found across millions of lines
    // of code are supposed to trigger compiler errors.
    void traverseBasicLiteral(literalInt(_)) {
        fileFeatures.lf.intLiterals += 1;
    }
    void traverseBasicLiteral(literalFloat(_)) {
        fileFeatures.lf.floatLiterals += 1;
    }
    void traverseBasicLiteral(literalImaginary(_,_)) {
        fileFeatures.lf.imaginaryLiterals += 1;
    } 
    void traverseBasicLiteral(literalChar(_)) {
        fileFeatures.lf.charLiterals += 1;
    }
    void traverseBasicLiteral(literalString(_)) {
        fileFeatures.lf.stringLiterals += 1;
    }
    void traverseBasicLiteral(unknownLiteral(_))  {
        ; // Just ignore these, these are generally all compiler tests
    }

    void traverseUnaryOp(Op op) {
        switch(op) {
            case add() : { fileFeatures.uops.addOps += 1; }
            case sub() : { fileFeatures.uops.subOps += 1; }
            case mul() : { fileFeatures.uops.mulOps += 1; }
            case quo() : { fileFeatures.uops.quoOps += 1; }
            case rem() : { fileFeatures.uops.remOps += 1; }
            case and() : { fileFeatures.uops.andOps += 1; }
            case or() : { fileFeatures.uops.orOps += 1; }
            case xor() : { fileFeatures.uops.xorOps += 1; }
            case shiftLeft() : { fileFeatures.uops.shiftLeftOps += 1; }
            case shiftRight() : { fileFeatures.uops.shiftRightOps += 1; }
            case andNot() : { fileFeatures.uops.andNotOps += 1; }
            case logicalAnd() : { fileFeatures.uops.logicalAndOps += 1; }
            case logicalOr() : { fileFeatures.uops.logicalOrOps += 1; }
            case arrow() : { fileFeatures.uops.arrowOps += 1; }
            case inc() : { fileFeatures.uops.incOps += 1; }
            case dec() : { fileFeatures.uops.decOps += 1; }
            case equal() : { fileFeatures.uops.equalOps += 1; }
            case lessThan() : { fileFeatures.uops.lessThanOps += 1; }
            case greaterThan() : { fileFeatures.uops.greaterThanOps += 1; }
            case not() : { fileFeatures.uops.notOps += 1; }
            case notEqual() : { fileFeatures.uops.notEqualOps += 1; }
            case lessThanEq() : { fileFeatures.uops.lessThanEqOps += 1; }
            case greaterThanEq() : { fileFeatures.uops.greaterThanEqOps += 1; }
            case tilde() : { fileFeatures.uops.tildeOps += 1; }
        }
    }

    void traverseBinaryOp(Op op) {
        switch(op) {
            case add() : { fileFeatures.bops.addOps += 1; }
            case sub() : { fileFeatures.bops.subOps += 1; }
            case mul() : { fileFeatures.bops.mulOps += 1; }
            case quo() : { fileFeatures.bops.quoOps += 1; }
            case rem() : { fileFeatures.bops.remOps += 1; }
            case and() : { fileFeatures.bops.andOps += 1; }
            case or() : { fileFeatures.bops.orOps += 1; }
            case xor() : { fileFeatures.bops.xorOps += 1; }
            case shiftLeft() : { fileFeatures.bops.shiftLeftOps += 1; }
            case shiftRight() : { fileFeatures.bops.shiftRightOps += 1; }
            case andNot() : { fileFeatures.bops.andNotOps += 1; }
            case logicalAnd() : { fileFeatures.bops.logicalAndOps += 1; }
            case logicalOr() : { fileFeatures.bops.logicalOrOps += 1; }
            case arrow() : { fileFeatures.bops.arrowOps += 1; }
            case inc() : { fileFeatures.bops.incOps += 1; }
            case dec() : { fileFeatures.bops.decOps += 1; }
            case equal() : { fileFeatures.bops.equalOps += 1; }
            case lessThan() : { fileFeatures.bops.lessThanOps += 1; }
            case greaterThan() : { fileFeatures.bops.greaterThanOps += 1; }
            case not() : { fileFeatures.bops.notOps += 1; }
            case notEqual() : { fileFeatures.bops.notEqualOps += 1; }
            case lessThanEq() : { fileFeatures.bops.lessThanEqOps += 1; }
            case greaterThanEq() : { fileFeatures.bops.greaterThanEqOps += 1; }
            case tilde() : { fileFeatures.bops.tildeOps += 1; }
        }
    }

    void traverseAssignOp(AssignOp op) {
        switch(op) {
            case addAssign() : { fileFeatures.aops.addAssignOps += 1; }
            case subAssign() : { fileFeatures.aops.subAssignOps += 1; }
            case mulAssign() : { fileFeatures.aops.mulAssignOps += 1; }
            case quoAssign() : { fileFeatures.aops.quoAssignOps += 1; }
            case remAssign() : { fileFeatures.aops.remAssignOps += 1; }
            case andAssign() : { fileFeatures.aops.andAssignOps += 1; }
            case orAssign() : { fileFeatures.aops.orAssignOps += 1; }
            case xorAssign() : { fileFeatures.aops.xorAssignOps += 1; }
            case shiftLeftAssign() : { fileFeatures.aops.shiftLeftAssignOps += 1; }
            case shiftRightAssign() : { fileFeatures.aops.shiftRightAssignOps += 1; }
            case andNotAssign() : { fileFeatures.aops.andNotAssignOps += 1; }
            case defineAssign() : { fileFeatures.aops.defineAssignOps += 1; }
            case assign() : { fileFeatures.aops.assignOps += 1; }
            case noKey() : { fileFeatures.aops.noKeyOps += 1; }
        }
    }

    // Traverse the individual decls in the file. This will recursively call the traversal
    // functions defined just above.
    for (d <- decls) traverseDecl(d);
    return fileFeatures;
}

public map[loc, ClocResult] slocForCorpus() {
    map[loc, ClocResult] result = ( );
    for (sname <- getSystemNames()) {
        logMessage("Computing SLOC for <sname>", 1);
        l = systemsDir + sname;
        cres = goLinesOfCode(l, clocLoc);
        result[l] = cres;
    }
    return result;
}

public void saveSlocInfo(map[loc, ClocResult] results) {
    writeBinaryValueFile(serializedDir + "clocinfo/go-cloc.bin", results);
}

public map[loc, ClocResult] loadSlocInfo() {
    return readBinaryValueFile(#map[loc, ClocResult], serializedDir + "clocinfo/go-cloc.bin");
}

public ClocResult mergeClocResults(map[loc, ClocResult] results) {
    // res = clocResult(0,0,0,0);
    // for (l <- results) {
    //     ClocResult cr = results[l];
    //     logMessage("<cr>",1);
    //     res.files += cr.files;
    // }
    // return res;
    return ( clocResult(0,0,0,0) |
             clocResult(it.files + results[l].files, 
                it.blankLines + results[l].blankLines,
                it.commentLines + results[l].commentLines,
                it.sourceLines + results[l].sourceLines) |
             l <- results );
}

public void saveClocResultsToCSV(map[loc, ClocResult] results, loc csvLoc) {
    rel[str systemName, int files, int blankLines, int commentLines, int sourceLines] clocRel = { };
    for (l <- results) {
        clocRel = clocRel + < l.file, results[l].files, results[l].blankLines, results[l].commentLines, results[l].sourceLines >;
    }
    writeCSV(#rel[str systemName, int files, int blankLines, int commentLines, int sourceLines],
        clocRel, csvLoc);
}