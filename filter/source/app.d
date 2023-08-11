import std.stdio,
			 std.json,
			 std.algorithm;

import argparse;

import classfilter,
			 common;

/// CLI Options
struct Options{
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
	@NamedArgument(["pretty-print", "p"])
		bool prettyPrint = false;
}
version (unittest) {} else
	mixin CLI!Options.main!(run);

void run(Options opts){
	Filters filters;
	filters.sectionsRel = opts.sections;
	filters.coursesRel = opts.courses;
	if (!opts.courses.length &&
			!opts.coursesSection.length &&
			!opts.sections.length)
		filters.coursesRel = [".*"];

	filters.sectionsNeg = opts.sectionsNeg;
	filters.coursesNeg = opts.coursesNeg;

	filters.coursesSectionRel = separateSectionCourse(opts.coursesSection);
	filters.coursesSectionNeg = separateSectionCourse(opts.coursesSectionNeg);

	char[] input;
	foreach (ubyte[] buf; chunks(stdin, 4096))
		input ~= cast(char[])buf;
	JSONValue[] timetables = parseJSON(input).get!(JSONValue[]);
	foreach (i, classesJson; timetables){
		JSONValue[] classes = classesJson.get!(JSONValue[]);
		JSONValue[] filtered;
		foreach (c; classes.filter!(a => matches(filters,Class(a))))
			filtered ~= c;
		timetables[i] = JSONValue(filtered);
	}

	if (opts.prettyPrint)
		writeln(JSONValue(timetables).toPrettyString);
	else
		writeln(JSONValue(timetables).toString);
}
