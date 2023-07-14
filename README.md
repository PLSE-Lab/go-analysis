Note: this project is still in an early stage, look for more updates coming soon!

# Go Analysis in Rascal

The Go AiR (Analysis in Rascal) framework is a program analysis framework for Go programs. The framework is written in Rascal, with the intent that it either be extended directly or included as a dependency in another Rascal project.

# Getting Started

To start, you will want to clone the project (please fork first if you want to contribute back!). You should also clone the [go2rascal](https://github.com/PLSE-Lab/go2rascal) project, which provides support for parsing Go source files and projects and converting these into a Rascal AST format, based on the AST types defined here in `lang::go::ast::AbstractSyntax`.

After cloning the project, you should copy the file /src/main/rascal/lang/go/config/Config.rsc-dist to just Config.rsc in the same directory. This will be loaded as module `lang::go::config::Config`. An example configuration is shown below:

```
module lang::go::config::Config

@doc{The location of the Go executable}
public loc goLoc = |file:///opt/homebrew/bin/go|;

@doc{The base install location for the go2rascal project}
public loc parserDir = |file:///Users/hillsma/Projects/go-analysis/go2rascal|;

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
```

You need to have Go installed somewhere on your computer. The `goLoc` variable holds the location of this executable. If you use a Mac with Homebrew this should work without modification. Otherwise, you will want to set this to the location on your own computer.

The variable `parserDir` is set to the location of the go2rascal project mentioned above. Just set this to the root of the project directory for the cloned project.

The `logLevel` determines which log messages you will see. It's generally useful to leave it at `2`, but you can set it to `0` if you do not want to see any messages.

# Loading a Go file into Rascal

With the configuration done, you can load a Go file into Rascal. A single file is represented using the `File` AST type. To load it, you should load the modules for utilities and for the AST first:

```
rascal>import lang::go::ast::AbstractSyntax;
ok
rascal>import lang::go::util::Utils;
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
accessed as `mySystem.files`.

Note that both `loadGoFile` and `loadGoFiles` have an optional keyword parameter `addLocationAnnotations`. Setting this to `false`, e.g., `loadGoFile(|file:///tmp/sample.go|, addLocationAnnotations=false)` will generate an AST that does not include location information. Otherwise, each AST node includes an `at` field that returns the location in the source code that is related to the AST node. Adding location information is recommended, both for code querying and for analyses that may need this information. 

# Coming Soon

We are currently adding AST types, and will also add functionality that will allow you to load an entire Go system into a variable of the `System` type, as defined in `lang::go::ast::System`.