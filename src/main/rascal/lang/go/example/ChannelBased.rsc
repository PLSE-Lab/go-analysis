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