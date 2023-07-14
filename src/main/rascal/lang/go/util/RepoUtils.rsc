module lang::go::util::RepoUtils

import util::git::Git;
import lang::go::util::Utils;
import lang::go::ast::System;
import lang::go::config::Config;
import Exception;
import IO;

public void buildTags(str product) {
    systemLoc = systemsDir + product;

    if (exists(systemLoc) && isDirectory(systemLoc)) {
        openLocalRepository(systemLoc);
        tags = getTags(systemLoc);
        for (t <- tags) {
            switchToTag(systemLoc, t);
            buildVersionedSystemBinary(product, t, addLocationAnnotations=true);
        }
    } else {
        throw IllegalArgument(product, "Cannot build tagged versions, missing repository.");
    }
}

public list[str] getTags(str product) {
    systemLoc = systemsDir + product;

    if (exists(systemLoc) && isDirectory(systemLoc)) {
        openLocalRepository(systemLoc);
        tags = getTags(systemLoc);
        return tags;
    } else {
        throw IllegalArgument(product, "Cannot load tags, missing repository.");
    }
}
