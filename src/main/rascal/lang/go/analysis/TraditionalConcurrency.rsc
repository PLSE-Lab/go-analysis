module lang::go::analysis::TraditionalConcurrency

import lang::go::ast::AbstractSyntax;
import lang::go::ast::System;
import util::Maybe;
import IO;
import Set;
import Map;
import List;
import Node;

private list[str] featureDecls = ["waitGroupDecl", "condDecl", "onceDecl", "mutexDecl", "rwMutexDecl", "lockerDecl"];
private list[str] waitGroupCalls = ["waitGroupDone", "waitGroupAdd", "waitGroupWait"];
private list[str] mutexCalls = ["mutexLock", "mutexUnlock", "mutexTryLock"];
private list[str] rwMutexCalls = ["rwMutexLock", "rwMutexUnlock", "rwMutexTryLock","rwMutexTryRLock", "rwMutexRLocker"];
private list[str] lockerCalls = ["lockerLock", "lockerUnlock"];
private list[str] condCalls = ["condLock", "condUnlock", "condWait","condSignal", "condBroadcast", "condNew"];
private list[str] onceCalls = ["onceDo"];
private list[str] unknownCalls = ["unknownDone", "unknownAdd", "unknownWait", "unknownLock", "unknownUnlock",
    "unknownTryLock", "unknownRLock", "unknownRUnlock", "unknownTryRLock", "unknownRLocker", "unknownSignal",
    "unknownBroadcast", "unknownDo"];
private list[str] featureCalls = waitGroupCalls + mutexCalls + rwMutexCalls + 
    lockerCalls + condCalls + onceCalls + unknownCalls;

data FeatureCounts
    = traditionalFeatureCounts(
        map[str feature, int count] declCounts, 
        map[str feature, int count] callCounts,
        map[str feature, int count] unknownCallCounts)
    ;

data FeatureSummary
    = traditionalConcurrencySummary(
        rel[str,loc,FeatureDecl] decls,
        rel[str,loc,Expr,str] calls,
        rel[str,loc,Expr] unknownCalls
    );

public FeatureSummary createEmptyTraditionalConcurrencySummary()
    = traditionalConcurrencySummary({}, {}, {});

data FeatureDecl = featureDecl(loc at, str name, DeclType declType);

data DeclType 
    = waitGroupDecl() 
    | mutexDecl() 
    | rwMutexDecl() 
    | lockerDecl() 
    | onceDecl() 
    | condDecl()
    ;

@doc{
    Create an initial version of the traditional concurrency features value,
    with all numbers set at 0.
}
private FeatureCounts initTraditionalConcurrencyFeatures()
    = traditionalFeatureCounts( 
        (f : 0 | f <- (featureDecls)),
        (f : 0 | f <- (featureCalls - unknownCalls)),
        (f : 0 | f <- (unknownCalls)) )
    ;


public Maybe[str] findFinalName(ident(str name)) = just(name);
public Maybe[str] findFinalName(selectorExpr(Expr expr, str selector)) = just(selector);
public Maybe[str] findFinalName(starExpr(Expr expr)) = findFinalName(expr);
public default Maybe[str] findFinalName(Expr e) = nothing();

public FeatureSummary computeFileSummary(File f) {
    FeatureSummary fs = traditionalConcurrencySummary({}, {}, {});
    rel[str,DeclType] declsForName = { };
    
    // Find structure types that contain embedded types
    rel[Expr t, loc at] typesWithEmbedded 
        = { < st, st.at > | /st:structType(flds) := f, fld <- flds, field([],_,_) := fld };

    // Find type specs with these embedded types, match on location to
    // make sure the type in the spec is one we found above.
    rel[str n, Expr t, loc at] namedEmbeddedTypes 
        = { < n, t, t.at > | /typeSpec(n,_,t) := f, t.at in typesWithEmbedded<1> };

    // Build a relation specifically of embedded types
    rel[Expr n, Expr et] embeddedTypeRel
        = { < ident(n), unsetRec(et) > | < n, t, l > <- namedEmbeddedTypes, structType(flds) := t, field([],someExpr(et),_) <- flds };

    // First, extract all declarations of relevant features from the given
    // file. We need these below as a heuristic -- if we have declared wg as
    // a waitgroup, a call to Done on wg will be a call of the WaitGroup Done
    // function. Note that this is not precise, since this is done on a
    // per-file level, leading to problems with names used in different
    // scopes with different types.
    bool isWaitGroupType(selectorExpr(ident("sync"),"WaitGroup")) = true;
    bool isWaitGroupType(i:ident(str _)) = size({ et | et <- (embeddedTypeRel+)[i], isWaitGroupType(et)}) > 0;
    bool isWaitGroupType(starExpr(Expr e)) = isWaitGroupType(e);
    default bool isWaitGroupType(Expr e) = false;
    bool isWaitGroup(someExpr(t)) = isWaitGroupType(unsetRec(t));
    default bool isWaitGroup(OptionExpr oe) = false;

    bool isMutexType(selectorExpr(ident("sync"),"Mutex")) = true;
    bool isMutexType(i:ident(str _)) = size({ et | et <- (embeddedTypeRel+)[i], isMutexType(et)}) > 0;
    bool isMutexType(starExpr(Expr e)) = isMutexType(e);
    default bool isMutexType(Expr e) = false;
    bool isMutex(someExpr(t)) = isMutexType(unsetRec(t));
    default bool isMutex(OptionExpr oe) = false;

    bool isRWMutexType(selectorExpr(ident("sync"),"RWMutex")) = true;
    bool isRWMutexType(i:ident(str _)) = size({ et | et <- (embeddedTypeRel+)[i], isRWMutexType(et)}) > 0;
    bool isRWMutexType(starExpr(Expr e)) = isRWMutexType(e);
    default bool isRWMutexType(Expr e) = false;
    bool isRWMutex(someExpr(t)) = isRWMutexType(unsetRec(t));
    default bool isRWMutex(OptionExpr oe) = false;

    bool isLockerType(selectorExpr(ident("sync"),"Locker")) = true;
    bool isLockerType(i:ident(str _)) = size({ et | et <- (embeddedTypeRel+)[i], isLockerType(et)}) > 0;
    bool isLockerType(starExpr(Expr e)) = isLockerType(e);
    default bool isLockerType(Expr e) = false;
    bool isLocker(someExpr(t)) = isLockerType(unsetRec(t));
    default bool isLocker(OptionExpr oe) = false;

    bool isOnceType(selectorExpr(ident("sync"),"Once")) = true;
    bool isOnceType(i:ident(str _)) = size({ et | et <- (embeddedTypeRel+)[i], isOnceType(et)}) > 0;
    bool isOnceType(starExpr(Expr e)) = isOnceType(e);
    default bool isOnceType(Expr e) = false;
    bool isOnce(someExpr(t)) = isOnceType(unsetRec(t));
    default bool isOnce(OptionExpr oe) = false;

    bool isCondType(selectorExpr(ident("sync"),"Cond")) = true;
    bool isCondType(i:ident(str _)) = size({ et | et <- (embeddedTypeRel+)[i], isCondType(et)}) > 0;
    bool isCondType(starExpr(Expr e)) = isCondType(e);
    default bool isCondType(Expr e) = false;
    bool isCond(someExpr(t)) = isCondType(unsetRec(t));
    default bool isCond(OptionExpr oe) = false;
    
    // TODO: We will not find inline struct definitions with embedded concurrency types
    // using this, but this may be a very niche use case.
    visit(f) {
        case genDecl(varDecl(), decls): {
            for (d <- decls, valueSpec(names,oe,_) := d) {
                if (isWaitGroup(oe)) {
                    fs.decls += { < "waitGroupDecl", d.at, featureDecl(d.at, n, waitGroupDecl())> | n <- names };
                } else if (isMutex(oe)) {
                    fs.decls += { < "mutexDecl", d.at, featureDecl(d.at, n, mutexDecl())> | n <- names };
                } else if (isRWMutex(oe)) {
                    fs.decls += { < "rwMutexDecl", d.at, featureDecl(d.at, n, rwMutexDecl())> | n <- names };
                } else if (isLocker(oe)) {
                    fs.decls += { < "lockerDecl", d.at, featureDecl(d.at, n, lockerDecl())> | n <- names };
                } else if (isOnce(oe)) {
                    fs.decls += { < "onceDecl", d.at, featureDecl(d.at, n, onceDecl())> | n <- names };
                } else if (isCond(oe)) {
                    fs.decls += { < "condDecl", d.at, featureDecl(d.at, n, condDecl())> | n <- names };
                }
            }
        }

        case d:field(list[str] names, OptionExpr fieldType, OptionBasicLiteral _): {
            if (isWaitGroup(fieldType)) {
                fs.decls += { < "waitGroupDecl", d.at, featureDecl(d.at, n, waitGroupDecl())> | n <- names};
            } else if (isMutex(fieldType)) {
                fs.decls += { < "mutexDecl", d.at, featureDecl(d.at, n, mutexDecl())> | n <- names};
            } else if (isRWMutex(fieldType)) {
                fs.decls += { < "rwMutexDecl", d.at, featureDecl(d.at, n, rwMutexDecl())> | n <- names};
            } else if (isLocker(fieldType)) {
                fs.decls += { < "lockerDecl", d.at, featureDecl(d.at, n, lockerDecl())> | n <- names};
            } else if (isOnce(fieldType)) {
                fs.decls += { < "onceDecl", d.at, featureDecl(d.at, n, onceDecl())> | n <- names};
            } else if (isCond(fieldType)) {
                fs.decls += { < "condDecl", d.at, featureDecl(d.at, n, condDecl())> | n <- names};
            }
        }

        case a:assignStmt(list[Expr] targets, list[Expr] values, AssignOp _): {
            if (size(targets) == size(values)) {
                for (i <- index(targets)) {
                    if (callExpr(selectorExpr(ident("sync"), "NewCond"), [], false) := values[i]) {
                        if (just(n) := findFinalName(targets[i])) {
                            fs.decls += { < "condDecl", a.at, featureDecl(a.at, n, condDecl()) > };
                        }
                    }
                }
            } else if (size(values) == 1 && size(targets) > 1) {
                if (callExpr(selectorExpr(ident("sync"), "NewCond"), [], false) := values[0]) {
                    if (just(n) := findFinalName(targets[0])) {
                        fs.decls += { < "condDecl", a.at, featureDecl(a.at, n, condDecl()) > };
                    }
                }
            }
        }
    }
    
    // For each name, compute a relation mapping it to the types of declarations
    // for that name found in the file.
    declsForName = { < fd.name, fd.declType > | fd <- fs.decls<2> };

    // Now, find calls to concurrency-related functions. 
    visit(f) {
        case e:selectorExpr(Expr expr, "Done") : {
            if (just(n) := findFinalName(expr), { waitGroupDecl() } := declsForName[n]) {
                fs.calls += { < "waitGroupDone", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownDone", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "Add") : {
            if (just(n) := findFinalName(expr), { waitGroupDecl() } := declsForName[n]) {
                fs.calls += { < "waitGroupAdd", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownAdd", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "Wait") : {
            if (just(n) := findFinalName(expr), { waitGroupDecl() } := declsForName[n]) {
                fs.calls += { < "waitGroupWait", e.at, e, n > };
            } else if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                fs.calls += { < "condWait", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownWait", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "Lock") : {
            if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                fs.calls += { < "condLock", e.at, e, n > };
            } else if (just(n) := findFinalName(expr), { mutexDecl() } := declsForName[n]) {
                fs.calls += { < "mutexLock", e.at, e, n > };
            } else if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                fs.calls += { < "rwMutexLock", e.at, e, n > };
            } else if (just(n) := findFinalName(expr), { lockerDecl() } := declsForName[n]) {
                fs.calls += { < "lockerLock", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownLock", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "RLock") : {
            if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                fs.calls += { < "rwMutexRLock", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownRLock", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "Unlock") : {
            if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                fs.calls += { < "condUnlock", e.at, e, n > };
            } else if (just(n) := findFinalName(expr), { mutexDecl() } := declsForName[n]) {
                fs.calls += { < "mutexUnlock", e.at, e, n > };
            } else if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                fs.calls += { < "rwMutexUnlock", e.at, e, n > };
            } else if (just(n) := findFinalName(expr), { lockerDecl() } := declsForName[n]) {
                fs.calls += { < "lockerUnlock", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownUnlock", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "RUnlock") : {
            if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                fs.calls += { < "rwMutexUnlock", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownRUnlock", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "TryLock") : {
            if (just(n) := findFinalName(expr), { mutexDecl() } := declsForName[n]) {
                fs.calls += { < "mutexTryLock", e.at, e, n > };
            } else if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                fs.calls += { < "rwMutexTryLock", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownTryLock", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "TryRLock") : {
            if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                fs.calls += { < "rwMutexTryRLock", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownTryRLock", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "RLocker") : {
            if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                fs.calls += { < "rwMutexRLocker", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownRLocker", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "Signal") : {
            if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                fs.calls += { < "condSignal", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownSignal", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "Broadcast") : {
            if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                fs.calls += { < "condBroadcast", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownBroadcast", e.at, e > };
            }
        }

        case e:selectorExpr(Expr expr, "Do") : {
            if (just(n) := findFinalName(expr), { onceDecl() } := declsForName[n]) {
                fs.calls += { < "onceDo", e.at, e, n > };
            } else {
                fs.unknownCalls += { < "unknownDo", e.at, e > };
            }
        }

        case e:selectorExpr(ident("sync"), "NewCond") : {
            fs.calls += { < "condNew", e.at, e, "sync" > };
        }
}

    // Return final summary result
    return fs;
}

public FeatureSummary mergeSummaries(FeatureSummary fs1, FeatureSummary fs2) 
    = traditionalConcurrencySummary(
        fs1.decls + fs2.decls,
        fs1.calls + fs2.calls,
        fs1.unknownCalls + fs2.unknownCalls
    );

public FeatureSummary computeSystemSummary(System pt) {
    res = createEmptyTraditionalConcurrencySummary();
    for (l <- pt.files<0>) {
        res = mergeSummaries(res, computeFileSummary(pt.files[l]));
    }
    return res;
}


public FeatureCounts computeTraditionalFeatureCounts(FeatureSummary fs) {
    fc = initTraditionalConcurrencyFeatures();
    for (d <- featureDecls) {
        fc.declCounts[d] = size(fs.decls[d]);
    }
    for (c <- (featureCalls - unknownCalls)) {
        fc.callCounts[c] = size(fs.calls[c]);
    }
    for (c <- unknownCalls) {
        fc.unknownCallCounts[c] = size(fs.unknownCalls[c]);
    }
    return fc;
}