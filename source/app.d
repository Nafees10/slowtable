import std.stdio;
import std.datetime;

import argparse;

import fasttable;
import tablegen;

/// CLI options
struct Options{
	@PositionalArgument(0, "file")
	string file = "input.ods";

	@NamedArgument(["courses", "c"])
	string[] courses;

	@NamedArgument(["sections", "s"])
	string[] sections;

	@NamedArgument(["PositiveTimeOffset", "tp"])
	int posTimeOff = 0;

	@NamedArgument(["NegativeTimeOffset", "np"])
	int negTimeOff = 10;
}
version (unittest) {} else
	mixin CLI!Options.main!(run);

void run(Options args){
	const int timeOffset = args.posTimeOff - args.negTimeOff;
	Parser parser = new Parser(args.file);
	parser.timeOffset = dur!"minutes"(timeOffset);
	parser.colDur = dur!"minutes"(10); // 1 column is 10 minutes
	parser.relSections = args.sections;
	parser.relCourses = args.courses;
	Class[] classes = parser.parse;
	//foreach (c; classes) writeln(c);
	writeln(generateTable(classes));
}
