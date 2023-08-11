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

	@NamedArgument(["interval", "i"])
		uint interval = 10;

	@NamedArgument(["positive-time-offset", "tp"])
		int positiveTimeOffset = 0;

	@NamedArgument(["negative-time-offset", "np"])
		int negativeTimeOffset = 10;

	@NamedArgument(["pretty-print", "p"])
		bool prettyPrint = false;
}

version (unittest) {} else
	mixin CLI!Options.main!(run);

void run(Options opts){
	const int timeOffset = opts.positiveTimeOffset - opts.negativeTimeOffset;
	Parser parser = Parser(opts.file, opts.sheetNumber);
	parser.timeOffset = dur!"minutes"(timeOffset);
	parser.colDur = dur!"minutes"(opts.interval);

	Class[] classes = parser.parse;
	JSONValue[] jarr = new JSONValue[classes.length];
	foreach (i, c; classes)
		jarr[i] = c.jsonOf;
	JSONValue timetable;
	timetable["timetable"] = jarr;
	JSONValue timetables = JSONValue([timetable]);

	if (opts.prettyPrint)
		writeln(timetables.toPrettyString);
	else
		writeln(timetables.toString);
}
