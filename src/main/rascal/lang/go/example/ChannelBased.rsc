module lang::go::example::ChannelBased

import lang::go::ast::AbstractSyntax;
import lang::go::ast::System;
import lang::go::util::Utils;

import Node;

public data Capacity = capacityNotProvided() | capacityProvided(Expr e);

alias ChannelMakes = rel[loc callLocation, Expr channelType, Capacity cap];

public ChannelMakes findChannelMakes(System pt) {
    callsWithCapacity = { < c.at, unsetRec(ct), capacityProvided(unsetRec(cap)) > 
        | /c:callExpr(ident("make"),[ct:chanType(_,_),Expr cap],_) := pt };
    callsWithoutCapacity = { < c.at, unsetRec(ct), capacityNotProvided() > 
        | /c:callExpr(ident("make"),[ct:chanType(_,_)],_) := pt };
    return callsWithCapacity + callsWithoutCapacity;
}



alias ContextTypes = rel[loc contextLocation, Expr contextType];

alias ContextCalls = rel[loc callLocation, Expr contextCall];



public ContextTypes findContextTypes(System pt) {
    return { 
        < ctx.at, unsetRec(ctx) >
        | /ctx:selectorExpr(ident("context"), "Context") := pt };
}

public ContextCalls findBackgroundContextCalls(System pt) {
    return {
        <call.at, unsetRec(call)>
        | /call:callExpr(selectorExpr(ident("context"), "Background"), [], _ ) := pt };
}

public ContextCalls findTODOContextCalls(System pt) {
    return {
        < call.at, unsetRec(call) >
        | /call:callExpr(selectorExpr(ident("context"), "TODO"), [], _ ) := pt };
}

public ContextCalls findContextWithCancelCalls(System pt) {
    return {
        < call.at, unsetRec(call) >
        | /call:callExpr(selectorExpr(ident("context"), "WithCancel"), [_], _ ) := pt };

}

public ContextCalls findTimeoutContextCalls(System pt) {
    return {
        < call.at, unsetRec(call) > 
        | /call:callExpr( selectorExpr(ident("context"), "WithTimeout"), [_, _], _) := pt };
    
}

public ContextCalls findContextWithDeadlineCalls(System pt) {
    return {
        < call.at, unsetRec(call) > 
        | /call:callExpr( selectorExpr(ident("context"), "WithDeadline"), [_, _], _) := pt };
}

