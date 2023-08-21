import std.stdio,
			 std.json,
			 std.datetime;

import parser,
			 common;

import argparse;

/// CLI options
struct Options{
	@PositionalArgument(0, "file")
		string file = "timetable.ods";

	@NamedArgument(["sheet-number", "s"])
		uint sheetNumber = 0;

	@NamedArgument(["pretty-print", "p"])
		bool prettyPrint = false;
}

version (unittest) {} else
	mixin CLI!Options.main!(run);

void run(Options opts){
	Parser parser = Parser(opts.file, opts.sheetNumber);
	parser.startTime = TimeOfDay(8, 0);

	Class[] classes = parser.parse;
	JSONValue[] jarr = new JSONValue[classes.length];
	foreach (i, c; classes)
		jarr[i] = c.jsonOf;
	JSONValue timetables = JSONValue([jarr]);

	if (opts.prettyPrint)
		writeln(timetables.toPrettyString);
	else
		writeln(timetables.toString);
}
