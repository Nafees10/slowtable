import std.stdio,
			 std.json,
			 std.datetime;
import core.stdc.stdlib;

import parser,
			 common;

import argparse;

/// CLI options
struct Options{
	@PositionalArgument(0, "file")
		string file = "timetable.ods";

	@NamedArgument(["sheet-number", "s"])
		uint sheetNumber = 0;
}

version (unittest) {} else
	mixin CLI!Options.main!(run);

void run(Options opts){
	try{
		foreach (Class c; Parser(opts.file, opts.sheetNumber, TimeOfDay(8, 0)))
			writeln(c.serialize);
	} catch (Exception e){
		stderr.writeln(e.msg);
		exit(1);
	}
}
