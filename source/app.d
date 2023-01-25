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

	@NamedArgument(["negated-courses", "nc"])
	string[] coursesNeg;

	@NamedArgument(["sections", "s"])
	string[] sections;

	@NamedArgument(["negated-sections", "ns"])
	string[] sectionsNeg;

	@NamedArgument(["courses-section", "cs"])
	string[] coursesSection;

	@NamedArgument(["negated-courses-section", "ncs"])
	string[] coursesSectionNeg;

	@NamedArgument(["Interval", "i"])
	ubyte interval = 10;

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
	parser.colDur = dur!"minutes"(args.interval);

	parser.sectionsRel = args.sections;
	parser.coursesRel = args.courses;

	parser.sectionsNeg = args.sectionsNeg;
	parser.coursesNeg = args.coursesNeg;

	parser.coursesSectionRel = separateSectionCourse(args.coursesSection);
	parser.coursesSectionNeg = separateSectionCourse(args.coursesSectionNeg);

	Class[] classes = parser.parse;
	writeln(generateTable(classes, args.interval));
}
