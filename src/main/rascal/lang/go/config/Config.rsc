module lang::go::config::Config

import IO;
import Exception;
import Set;
import util::SystemAPI;
import lang::yaml::Model;
import lang::go::config::ConfigLoader;

public data Exception
	= configMissing(str key, str msg)
	;

@doc{Base configuration settings used by all parts of Go AiR.}
public data ConfigBase
	= configBase(
		int logLevel = 0,
		loc goLoc = |unknown:///|,
		loc clocLoc = |unknown:///|
	);

@doc{Config settings specifically related to parsing Go code.}
public data ConfigParsing
	= configParsing(
		loc parserWorkingDir = |unknown:///|,
		str go2rascalSrc = "go2rascal.go",
		str go2rascalBin = "go2rascal",
		bool runConverterBinary = true
	);

@doc{Config settings specifically for the analysis framework.}
public data ConfigAnalysis
	= configAnalysis(
		loc systemsDir = |unknown:///|,
		loc serializedDir = |unknown:///|
	);

@doc{The overall configuration used by PHP AiR and child projects.}
public data Config 
	= config(
		ConfigBase base = configBase(), 
		ConfigParsing parsing = configParsing(), 
		ConfigAnalysis analysis = configAnalysis())
	| unloaded()
	;

@doc{A singleton to hold the loaded configuration.}
private Config c = unloaded();

@doc{Manage the singleton, loading the config if it hasn't been loaded yet.}
public Config getConfig() {
	if (c is unloaded) {
		c = loadConfig();
	}
	return c;
}

@doc{Force a reload of the configuration.}
public Config reloadConfig() {
	c = loadConfig();
	return c;
}

@doc{Load the YAML configuration file.}
private Config loadConfig() {

	set[loc] configFiles = findResources("config.yaml");
	if (size(configFiles) == 0) {
		throw configMissing("", "No config.yaml file found");
	} else if (size(configFiles) > 1) {
		throw configMissing("", "Found <size(configFiles)> config.yaml files, should only have 1");
	} else {
		configFile = getOneFrom(configFiles);
		if (!exists(configFile)) {
			throw configMissing("", "The file <configFile.path> does not exist");
		} else if (!isFile(configFile)) {
			throw configMissing("", "<configFile.path> is not a file");
		} else {
			try {
				yml = loadYAML(readFile(configFile));
				Config c = yaml2config(#Config, yml);
				return c;
			} catch Exception e: {
				throw configMissing("", "The config file did not load correctly: <e>");
			}			
		}
	}
}
