module lang::go::analysis::TraditionalConcurrency

import lang::go::ast::AbstractSyntax;
import lang::go::ast::System;
import util::Maybe;
import IO;
import Set;
import Map;
import List;

data FeatureCounts
    = traditionalConcurrencyFeatures(
        int waitGroupDecls, int condDecls, int onceDecls, int mutexDecls,
        int rwMutexDecls, int lockerDecls, int waitGroupDone, int waitGroupAdd,
        int waitGroupWait, int mutexLock, int mutexUnlock, int mutexTryLock,
        int rwMutexLock, int rwMutexUnlock, int rwMutexTryLock,
        int rwMutexTryRLock, int rwMutexRLocker, int lockerLock,
        int lockerUnlock, int condLock, int condUnlock, int condWait,
        int condSignal, int condBroadcast, int condNew, int onceDo,
        int unknownDone, int unknownAdd, int unknownWait,
        int unknownLock, int unknownUnlock, int unknownTryLock,
        int unknownRLock, int unknownRUnlock, int unknownTryRLock,
        int unknownRLocker, int unknownSignal, int unknownBroadcast,
        int unknownDo
    )
    ;

data FeatureSummary
    = traditionalConcurrencySummary(
        rel[loc,FeatureDecl] waitGroupDecls,
        rel[loc,FeatureDecl] mutexDecls,
        rel[loc,FeatureDecl] rwMutexDecls,
        rel[loc,FeatureDecl] lockerDecls,
        rel[loc,FeatureDecl] onceDecls,
        rel[loc,FeatureDecl] condDecls,
        rel[loc,Expr,str] waitGroupDoneCalls,
        rel[loc,Expr,str] waitGroupAddCalls,
        rel[loc,Expr,str] waitGroupWaitCalls,
        rel[loc,Expr,str] condWaitCalls,
        rel[loc,Expr,str] condLockCalls,
        rel[loc,Expr,str] mutexLockCalls,
        rel[loc,Expr,str] rwMutexLockCalls,
        rel[loc,Expr,str] lockerLockCalls,
        rel[loc,Expr,str] rwMutexRLockCalls,
        rel[loc,Expr,str] condUnlockCalls,
        rel[loc,Expr,str] mutexUnlockCalls,
        rel[loc,Expr,str] rwMutexUnlockCalls,
        rel[loc,Expr,str] lockerUnlockCalls,
        rel[loc,Expr,str] rwMutexRUnlockCalls,
        rel[loc,Expr,str] mutexTryLockCalls,
        rel[loc,Expr,str] rwMutexTryLockCalls,
        rel[loc,Expr,str] rwMutexTryRLockCalls,
        rel[loc,Expr,str] rwMutexRLockerCalls,
        rel[loc,Expr,str] condSignalCalls,
        rel[loc,Expr,str] condBroadcastCalls,
        rel[loc,Expr,str] onceDoCalls,
        rel[loc,Expr,str] condNewCalls,
        rel[loc,Expr] unknownDoneCalls,
        rel[loc,Expr] unknownAddCalls,
        rel[loc,Expr] unknownWaitCalls,
        rel[loc,Expr] unknownLockCalls,
        rel[loc,Expr] unknownRLockCalls,
        rel[loc,Expr] unknownUnlockCalls,
        rel[loc,Expr] unknownRUnlockCalls,
        rel[loc,Expr] unknownTryLockCalls,
        rel[loc,Expr] unknownTryRLockCalls,
        rel[loc,Expr] unknownRLockerCalls,
        rel[loc,Expr] unknownSignalCalls,
        rel[loc,Expr] unknownBroadcastCalls,
        rel[loc,Expr] unknownDoCalls
    );

public FeatureSummary createEmptyTraditionalConcurrencySummary()
    = traditionalConcurrencySummary(
        {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
        {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {},
        {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
    );

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
    = traditionalConcurrencyFeatures(
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);


public Maybe[str] findFinalName(ident(str name)) = just(name);
public Maybe[str] findFinalName(selectorExpr(Expr expr, str selector)) = just(selector);
public Maybe[str] findFinalName(starExpr(Expr expr)) = findFinalName(expr);
public default Maybe[str] findFinalName(Expr e) = nothing();

public FeatureSummary computeFileSummary(File f) {
    rel[loc,FeatureDecl] featureDecls = { };
    rel[str,DeclType] declsForName = { };
    
    rel[loc,Expr,str] waitGroupDoneCalls = { };
    rel[loc,Expr,str] waitGroupAddCalls = { };
    rel[loc,Expr,str] waitGroupWaitCalls = { };
    rel[loc,Expr,str] condWaitCalls = { };
    rel[loc,Expr,str] condLockCalls = { };
    rel[loc,Expr,str] mutexLockCalls = { };
    rel[loc,Expr,str] rwMutexLockCalls = { };
    rel[loc,Expr,str] lockerLockCalls = { };
    rel[loc,Expr,str] rwMutexRLockCalls = { };
    rel[loc,Expr,str] condUnlockCalls = { };
    rel[loc,Expr,str] mutexUnlockCalls = { };
    rel[loc,Expr,str] rwMutexUnlockCalls = { };
    rel[loc,Expr,str] lockerUnlockCalls = { };
    rel[loc,Expr,str] rwMutexRUnlockCalls = { };
    rel[loc,Expr,str] mutexTryLockCalls = { };
    rel[loc,Expr,str] rwMutexTryLockCalls = { };
    rel[loc,Expr,str] rwMutexTryRLockCalls = { };
    rel[loc,Expr,str] rwMutexRLockerCalls = { };
    rel[loc,Expr,str] condSignalCalls = { };
    rel[loc,Expr,str] condBroadcastCalls = { };
    rel[loc,Expr,str] onceDoCalls = { };
    rel[loc,Expr,str] condNewCalls = { };

    rel[loc,Expr] unknownDoneCalls = { };
    rel[loc,Expr] unknownAddCalls = { };
    rel[loc,Expr] unknownWaitCalls = { };
    rel[loc,Expr] unknownLockCalls = { };
    rel[loc,Expr] unknownRLockCalls = { };
    rel[loc,Expr] unknownUnlockCalls = { };
    rel[loc,Expr] unknownRUnlockCalls = { };
    rel[loc,Expr] unknownTryLockCalls = { };
    rel[loc,Expr] unknownTryRLockCalls = { };
    rel[loc,Expr] unknownRLockerCalls = { };
    rel[loc,Expr] unknownSignalCalls = { };
    rel[loc,Expr] unknownBroadcastCalls = { };
    rel[loc,Expr] unknownDoCalls = { };
    
    // First, extract all declarations of relevant features from the given
    // file. We need these below as a heuristic -- if we have declared wg as
    // a waitgroup, a call to Done on wg will be a call of the WaitGroup Done
    // function. Note that this is not precise, since this is done on a
    // per-file level, leading to problems with names used in different
    // scopes with different types.
    visit(f) {
        case genDecl(varDecl(), decls): {
            for (d <- decls) {
                // Find var declarations of type sync.WaitGroup
                if (valueSpec(names,someExpr(selectorExpr(ident("sync"),"WaitGroup")),_) := d) {
                    featureDecls = featureDecls 
                        + { < d.at, featureDecl(d.at, n, waitGroupDecl())> | n <- names };
                }
                if (valueSpec(names,someExpr(selectorExpr(ident("sync"),"Mutex")),_) := d) {
                    featureDecls = featureDecls 
                        + { < d.at, featureDecl(d.at, n, mutexDecl())> | n <- names };
                }
                if (valueSpec(names,someExpr(selectorExpr(ident("sync"),"RWMutex")),_) := d) {
                    featureDecls = featureDecls 
                        + { < d.at, featureDecl(d.at, n, rwMutexDecl())> | n <- names };
                }
                if (valueSpec(names,someExpr(selectorExpr(ident("sync"),"Locker")),_) := d) {
                    featureDecls = featureDecls 
                        + { < d.at, featureDecl(d.at, n, lockerDecl())> | n <- names };
                }
                if (valueSpec(names,someExpr(selectorExpr(ident("sync"),"Once")),_) := d) {
                    featureDecls = featureDecls 
                        + { < d.at, featureDecl(d.at, n, onceDecl())> | n <- names };
                }
                if (valueSpec(names,someExpr(selectorExpr(ident("sync"),"Cond")),_) := d) {
                    featureDecls = featureDecls 
                        + { < d.at, featureDecl(d.at, n, condDecl())> | n <- names };
                }
            }
        }
        case d:field(list[str] names, OptionExpr fieldType, OptionBasicLiteral fieldTag): {
            // Find var declarations of type sync.WaitGroup
            if (someExpr(selectorExpr(ident("sync"),"WaitGroup")) := fieldType) {
                featureDecls = featureDecls 
                    + { < d.at, featureDecl(d.at, n, waitGroupDecl())> | n <- names};
            }
            if (someExpr(selectorExpr(ident("sync"),"Mutex")) := fieldType) {
                featureDecls = featureDecls 
                    + { < d.at, featureDecl(d.at, n, mutexDecl())> | n <- names};
            }
            if (someExpr(selectorExpr(ident("sync"),"RWMutex")) := fieldType) {
                featureDecls = featureDecls 
                    + { < d.at, featureDecl(d.at, n, rwMutexDecl())> | n <- names};
            }
            if (someExpr(selectorExpr(ident("sync"),"Locker")) := fieldType) {
                featureDecls = featureDecls 
                    + { < d.at, featureDecl(d.at, n, lockerDecl())> | n <- names};
            }
            if (someExpr(selectorExpr(ident("sync"),"Once")) := fieldType) {
                featureDecls = featureDecls 
                    + { < d.at, featureDecl(d.at, n, onceDecl())> | n <- names};
            }
            if (someExpr(selectorExpr(ident("sync"),"Cond")) := fieldType) {
                featureDecls = featureDecls 
                    + { < d.at, featureDecl(d.at, n, condDecl())> | n <- names};
            }
        }
        case a:assignStmt(list[Expr] targets, list[Expr] values, AssignOp assignOp): {
            if (size(targets) == size(values)) {
                for (i <- index(targets)) {
                    if (callExpr(selectorExpr(ident("sync"), "NewCond"), [], false) := values[i]) {
                        if (just(n) := findFinalName(targets[i])) {
                            featureDecls = featureDecls + < a.at, featureDecl(a.at, n, condDecl()) >;
                        }
                    }
                }
            } else if (size(values) == 1 && size(targets) > 1) {
                if (callExpr(selectorExpr(ident("sync"), "NewCond"), [], false) := values[0]) {
                    if (just(n) := findFinalName(targets[0])) {
                        featureDecls = featureDecls + < a.at, featureDecl(a.at, n, condDecl()) >;
                    }
                }
            }
        }
    }
    
    // For each name, compute a relation mapping it to the types of declarations
    // for that name found in the file.
    declsForName = { < fd.name, fd.declType > | fd <- featureDecls<1> };

    // Now, find calls to concurrency-related functions. 
    visit(f) {
        case e:selectorExpr(Expr expr, "Done") : {
            if (just(n) := findFinalName(expr), { waitGroupDecl() } := declsForName[n]) {
                waitGroupDoneCalls = waitGroupDoneCalls + < e.at, e, n >;
            } else {
                unknownDoneCalls = unknownDoneCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "Add") : {
            if (just(n) := findFinalName(expr), { waitGroupDecl() } := declsForName[n]) {
                waitGroupAddCalls = waitGroupAddCalls + < e.at, e, n >;
            } else {
                unknownAddCalls = unknownAddCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "Wait") : {
            if (just(n) := findFinalName(expr), { waitGroupDecl() } := declsForName[n]) {
                waitGroupAddCalls = waitGroupAddCalls + < e.at, e, n >;
            } else if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                condWaitCalls = condWaitCalls + < e.at, e, n >;
            } else {
                unknownWaitCalls = unknownWaitCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "Lock") : {
            if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                condLockCalls = condLockCalls + < e.at, e, n >;
            } else if (just(n) := findFinalName(expr), { mutexDecl() } := declsForName[n]) {
                mutexLockCalls = mutexLockCalls + < e.at, e, n >;
            } else if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                rwMutexLockCalls = rwMutexLockCalls + < e.at, e, n >;
            } else if (just(n) := findFinalName(expr), { lockerDecl() } := declsForName[n]) {
                lockerLockCalls = lockerLockCalls + < e.at, e, n >;
            } else {
                unknownLockCalls = unknownLockCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "RLock") : {
            if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                rwMutexRLockCalls = rwMutexRLockCalls + < e.at, e, n >;
            } else {
                unknownRLockCalls = unknownRLockCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "Unlock") : {
            if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                condUnlockCalls = condUnlockCalls + < e.at, e, n >;
            } else if (just(n) := findFinalName(expr), { mutexDecl() } := declsForName[n]) {
                mutexUnlockCalls = mutexUnlockCalls + < e.at, e, n >;
            } else if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                rwMutexUnlockCalls = rwMutexUnlockCalls + < e.at, e, n >;
            } else if (just(n) := findFinalName(expr), { lockerDecl() } := declsForName[n]) {
                lockerUnlockCalls = lockerUnlockCalls + < e.at, e, n >;
            } else {
                unknownUnlockCalls = unknownUnlockCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "RUnlock") : {
            if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                rwMutexRUnlockCalls = rwMutexRUnlockCalls + < e.at, e, n >;
            } else {
                unknownRUnlockCalls = unknownRUnlockCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "TryLock") : {
            if (just(n) := findFinalName(expr), { mutexDecl() } := declsForName[n]) {
                mutexTryLockCalls = mutexTryLockCalls + < e.at, e, n >;
            } else if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                rwMutexTryLockCalls = rwMutexTryLockCalls + < e.at, e, n >;
            } else {
                unknownTryLockCalls = unknownTryLockCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "TryRLock") : {
            if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                rwMutexTryRLockCalls = rwMutexTryRLockCalls + < e.at, e, n >;
            } else {
                unknownTryRLockCalls = unknownTryRLockCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "RLocker") : {
            if (just(n) := findFinalName(expr), { rwMutexDecl() } := declsForName[n]) {
                rwMutexRLockerCalls = rwMutexRLockerCalls + < e.at, e, n >;
            } else {
                unknownRLockerCalls = unknownRLockerCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "Signal") : {
            if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                condSignalCalls = condSignalCalls + < e.at, e, n >;
            } else {
                unknownSignalCalls = unknownSignalCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "Broadcast") : {
            if (just(n) := findFinalName(expr), { condDecl() } := declsForName[n]) {
                condBroadcastCalls = condBroadcastCalls + < e.at, e, n >;
            } else {
                unknownBroadcastCalls = unknownBroadcastCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(Expr expr, "Do") : {
            if (just(n) := findFinalName(expr), { onceDecl() } := declsForName[n]) {
                onceDoCalls = onceDoCalls + < e.at, e, n >;
            } else {
                unknownDoCalls = unknownDoCalls + < e.at, e >;
            }
        }

        case e:selectorExpr(ident("sync"), "NewCond") : {
            condNewCalls = condNewCalls + < e.at, e, "sync" >;
        }
}

    // Return final summary result
    return traditionalConcurrencySummary(
        { <l, fd > | <l, fd > <- featureDecls, fd.declType is waitGroupDecl },
        { <l, fd > | <l, fd > <- featureDecls, fd.declType is mutexDecl },
        { <l, fd > | <l, fd > <- featureDecls, fd.declType is rwMutexDecl },
        { <l, fd > | <l, fd > <- featureDecls, fd.declType is lockerDecl },
        { <l, fd > | <l, fd > <- featureDecls, fd.declType is onceDecl },
        { <l, fd > | <l, fd > <- featureDecls, fd.declType is condDecl },
        waitGroupDoneCalls,
        waitGroupAddCalls,
        waitGroupWaitCalls,
        condWaitCalls,
        condLockCalls,
        mutexLockCalls,
        rwMutexLockCalls,
        lockerLockCalls,
        rwMutexRLockCalls,
        condUnlockCalls,
        mutexUnlockCalls,
        rwMutexUnlockCalls,
        lockerUnlockCalls,
        rwMutexRUnlockCalls,
        mutexTryLockCalls,
        rwMutexTryLockCalls,
        rwMutexTryRLockCalls,
        rwMutexRLockerCalls,
        condSignalCalls,
        condBroadcastCalls,
        onceDoCalls,
        condNewCalls,
        unknownDoneCalls,
        unknownAddCalls,
        unknownWaitCalls,
        unknownLockCalls,
        unknownRLockCalls,
        unknownUnlockCalls,
        unknownRUnlockCalls,
        unknownTryLockCalls,
        unknownTryRLockCalls,
        unknownRLockerCalls,
        unknownSignalCalls,
        unknownBroadcastCalls,
        unknownDoCalls
    );
}

public FeatureSummary mergeSummaries(FeatureSummary fs1, FeatureSummary fs2) {
    return traditionalConcurrencySummary(
        fs1.waitGroupDecls + fs2.waitGroupDecls,
        fs1.mutexDecls + fs2.mutexDecls,
        fs1.rwMutexDecls + fs2.rwMutexDecls,
        fs1.lockerDecls + fs2.lockerDecls,
        fs1.onceDecls + fs2.onceDecls,
        fs1.condDecls + fs2.condDecls,
        fs1.waitGroupDoneCalls + fs2.waitGroupDoneCalls,
        fs1.waitGroupAddCalls + fs2.waitGroupAddCalls,
        fs1.waitGroupWaitCalls + fs2.waitGroupWaitCalls,
        fs1.condWaitCalls + fs2.condWaitCalls,
        fs1.condLockCalls + fs2.condLockCalls,
        fs1.mutexLockCalls + fs2.mutexLockCalls,
        fs1.rwMutexLockCalls + fs2.rwMutexLockCalls,
        fs1.lockerLockCalls + fs2.lockerLockCalls,
        fs1.rwMutexRLockCalls + fs2.rwMutexRLockCalls,
        fs1.condUnlockCalls + fs2.condUnlockCalls,
        fs1.mutexUnlockCalls + fs2.mutexUnlockCalls,
        fs1.rwMutexUnlockCalls + fs2.rwMutexUnlockCalls,
        fs1.lockerUnlockCalls + fs2.lockerUnlockCalls,
        fs1.rwMutexRUnlockCalls + fs2.rwMutexRUnlockCalls,
        fs1.mutexTryLockCalls + fs2.mutexTryLockCalls,
        fs1.rwMutexTryLockCalls + fs2.rwMutexTryLockCalls,
        fs1.rwMutexTryRLockCalls + fs2.rwMutexTryRLockCalls,
        fs1.rwMutexRLockerCalls + fs2.rwMutexRLockerCalls,
        fs1.condSignalCalls + fs2.condSignalCalls,
        fs1.condBroadcastCalls + fs2.condBroadcastCalls,
        fs1.onceDoCalls + fs2.onceDoCalls,
        fs1.condNewCalls + fs2.condNewCalls,
        fs1.unknownDoneCalls + fs2.unknownDoneCalls,
        fs1.unknownAddCalls + fs2.unknownAddCalls,
        fs1.unknownWaitCalls + fs2.unknownWaitCalls,
        fs1.unknownLockCalls + fs2.unknownLockCalls,
        fs1.unknownRLockCalls + fs2.unknownRLockCalls,
        fs1.unknownUnlockCalls + fs2.unknownUnlockCalls,
        fs1.unknownRUnlockCalls + fs2.unknownRUnlockCalls,
        fs1.unknownTryLockCalls + fs2.unknownTryLockCalls,
        fs1.unknownTryRLockCalls + fs2.unknownTryRLockCalls,
        fs1.unknownRLockerCalls + fs2.unknownRLockerCalls,
        fs1.unknownSignalCalls + fs2.unknownSignalCalls,
        fs1.unknownBroadcastCalls + fs2.unknownBroadcastCalls,
        fs1.unknownDoCalls + fs2.unknownDoCalls
    );
}

public FeatureSummary computeSystemSummary(System pt) {
    res = createEmptyTraditionalConcurrencySummary();
    for (l <- pt.files<0>) {
        res = mergeSummaries(res, computeFileSummary(pt.files[l]));
    }
    return res;
}

public FeatureCounts computeTraditionalFeatureCounts(FeatureSummary fs) {
    return traditionalConcurrencyFeatures(
        size(fs.waitGroupDecls),
        size(fs.condDecls),
        size(fs.onceDecls),
        size(fs.mutexDecls),
        size(fs.rwMutexDecls),
        size(fs.lockerDecls),
        size(fs.waitGroupDoneCalls),
        size(fs.waitGroupAddCalls),
        size(fs.waitGroupWaitCalls),
        size(fs.mutexLockCalls),
        size(fs.mutexUnlockCalls),
        size(fs.mutexTryLockCalls),
        size(fs.rwMutexLockCalls),
        size(fs.rwMutexUnlockCalls),
        size(fs.rwMutexTryLockCalls),
        size(fs.rwMutexTryRLockCalls),
        size(fs.rwMutexRLockerCalls),
        size(fs.lockerLockCalls),
        size(fs.lockerUnlockCalls),
        size(fs.condLockCalls),
        size(fs.condUnlockCalls),
        size(fs.condWaitCalls),
        size(fs.condSignalCalls),
        size(fs.condBroadcastCalls),
        size(fs.condNewCalls),
        size(fs.onceDoCalls),
        size(fs.unknownDoneCalls),
        size(fs.unknownAddCalls),
        size(fs.unknownWaitCalls),
        size(fs.unknownLockCalls),
        size(fs.unknownUnlockCalls),
        size(fs.unknownTryLockCalls),
        size(fs.unknownRLockCalls),
        size(fs.unknownRUnlockCalls),
        size(fs.unknownTryRLockCalls),
        size(fs.unknownRLockCalls),
        size(fs.unknownSignalCalls),
        size(fs.unknownBroadcastCalls),
        size(fs.unknownDoCalls)
    );
}