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