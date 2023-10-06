import std.stdio,
			 std.string;

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

	while (!stdin.eof){
		string line = readln.chomp("\n");
		Class c;
		try{
			c = Class.deserialize(line);
		} catch (Exception){
			continue;
		}
		if (matches(filters, c))
			writeln(line);
	}
}
