Note: this project is still in an early stage, look for more updates coming soon!

# Go Analysis in Rascal

The Go AiR (Analysis in Rascal) framework is a program analysis framework for Go programs. The framework is written in Rascal, with the intent that it either be extended directly or included as a dependency in another Rascal project.

A quick note: the framework should work regardless of how you are running Rascal. However, the assumption made below is that you are running it inside the VSCode Rascal plugin.

# Getting Started

To start, you will want to clone the project (please fork first if you want to contribute back!). You should also clone the [go2rascal](https://github.com/PLSE-Lab/go2rascal) project, which provides support for parsing Go source files and projects and converting these into a Rascal AST format, based on the AST types defined here in `lang::go::ast::AbstractSyntax`.

After cloning the project, you should copy the file /src/main/rascal/lang/go/config/Config.rsc-dist to just Config.rsc in the same directory. This will be loaded as module `lang::go::config::Config`. An example configuration is shown below:

```
module lang::go::config::Config

@doc{The location of the Go executable}
public loc goLoc = |file:///opt/homebrew/bin/go|;

@doc{The base install location for the go2rascal project}
public loc parserDir = |file:///Users/some-user/go-analysis/go2rascal|;

@doc{The source file containing the go2rascal code}
public str go2rascalSrc = "go2rascal.go";

@doc{The binary for the go2rascal program}
public str go2rascalBin = "go2rascal";

@doc{Debugging options
	@logLevel {
		Log level 0 => no logging;
		Log level 1 => main logging;
		Log level 2 => debug logging;
	}
}
public int logLevel = 2;

@doc{Run the go2rascal binary (true), or run from source? (false)}
public bool runConverterBinary = true;

@doc{The location of the systems being investigated}
public loc systemsDir = |file:///Users/some-user/GoAnalysis/systems|;

@doc{The location where serialized information can be stored}
public loc serializedDir = |file:///Users/some-user/GoAnalysis/serialized|;
```

You need to have Go installed somewhere on your computer. The `goLoc` variable holds the location of this executable. If you use a Mac with Homebrew this should work without modification. Otherwise, you will want to set this to the location on your own computer.

The variable `parserDir` is set to the location of the go2rascal project mentioned above. Just set this to the root of the project directory for the cloned project.

The `logLevel` determines which log messages you will see. It's generally useful to leave it at `2`, but you can set it to `0` if you do not want to see any messages.

`runConverterBinary` says whether to run the source version of go2rascal or the binary version. If you want to run the binary version, you need to compile it first. We recommend running the binary, though, since it's much faster (not noticeable on a single file, but noticeable across an entire system with many files). The source version is better to use while updating the AST format on either side, since it allows for testing without recompilation.

`systemsDir` indicates the directory that contains the systems to analyze. Go AiR includes functionality for working with all of the systems at once, e.g., to parse all the files in all systems and save each system into its own serialized binary. These serialized versions are put into `serializedDir`.

# Loading a Go file or system into Rascal

With the configuration done, you can load a Go file into Rascal. A single file is represented using the `File` AST type. To load it, you should load the modules for utilities and for the AST first. You can do this by first opening one of the included Rascal files (which provides the context for the Rascal terminal), then using the _Create Rascal Terminal_ command to create a new Rascal terminal. Then, run the following:

```
rascal>import lang::go::ast::AbstractSyntax;
ok
rascal>import lang::go::ast::System;
ok
rascal>import lang::go::util::Utils;
ok
rascal>import lang::go::config::Config;
ok
```

Now, you can load a single file using the `loadGoFile` function. For instance, you can load a Go source file, `/tmp/sample.go`, using the following command:

```
sampleAst = loadGoFile(|file:///tmp/sample.go|);
```

This will load the AST for the file and save it into variable `sampleAst`.

You can also load multiple files into a `System`. To do so, you use the `loadGoFiles` function.

```
mySystem = loadGoFiles(|file:///root/directory/for/system|);
```

All of the files will be stored in a `map` from the location of the file to the AST for the file,
accessed as `mySystem.files`. The expression `mySystem.files<0>` returns a set with all the files
included in the system.

Note that both `loadGoFile` and `loadGoFiles` have an optional keyword parameter `addLocationAnnotations`. Setting this to `false`, e.g., `loadGoFile(|file:///tmp/sample.go|, addLocationAnnotations=false)` will generate an AST that does not include location information. Otherwise, each AST node includes an `at` field that returns the location in the source code that is related to the AST node. Adding location information is recommended, both for code querying and for analyses that may need this information. 

# Building a Serialized Version of a System

If your system is in the `systemsDir`, you can parse it and save a serialized version to disk using the `buildSystemBinary` function, like:

```
// With location annotations
buildSystemBinary("docker-ce");

// Without location annotations
buildSystemBinary("docker-ce", addLocationAnnotations=false);
```

You can also build all the systems in the `systemsDir`:

```
buildSystemBinaries();
```

Once built, the ASTs for a system can be loaded directly, without having to parse the source for the system again:

```
docker = loadBinary("docker-ce");
```

# Building Specific Releases of a System

If your system is based on a Git repo, you can build a specific version, based on the tag marking the release. 

```
import util::git::Git;
dockerLoc = systemsDir + "docker-ce-full";
openLocalRepository(dockerLoc);
switchToTag(dockerLoc, "v19.03.8");
buildVersionedSystemBinary("docker-ce-full", "v19.03.8");
```

Once this is done, this version of the system can be loaded without needing to be parsed again:

```
docker = loadVersionedBinary("docker-ce-full", "v19.03.8");
```

Note that we are simplifying this so it will be easier to do as a single function. This example will be updated when that is complete.

# Building the New Corpus

The following changes were needed:
* Remove bitnami-labs-sealed-secrets/vendor_jsonnet/kube-libsonnet/examples/wordpress/lib


