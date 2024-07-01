module app.stparse;

import std.stdio,
			 std.path,
			 std.datetime,
			 std.conv : to;
import core.stdc.stdlib;

import slowtable.parser, slowtable.common;

void stparse_main(string[] args){
	string filename;
	uint sheetNumber;
	int offset;
	if (args.length < 2 || args[1] == "--help" || args[1] == "-h"){
		stderr.writefln!"Usage:\n\t%s timetable.ods [sheetIndex] [offset]"(args[0]);
		exit(1);
	}
	filename = args[1];
	if (args.length > 2){
		try{
			sheetNumber = args[2].to!uint;
		} catch (Exception){
			stderr.writeln("Invalid sheetIndex");
			exit(1);
		}
	}
	if (args.length > 3){
		try{
			offset = args[3].to!int;
		} catch (Exception){
			stderr.writeln("Invalid offset");
			exit(1);
		}
	}
	writefln!"%s[%d]"(filename.baseName, sheetNumber);
	try{
		foreach (Class c; Parser(filename, sheetNumber, TimeOfDay(8, 0))){
			c.time += dur!"minutes"(offset);
			writeln(c.serialize);
		}
	} catch (Exception e){
		stderr.writeln(e.msg);
		exit(1);
	}
	writeln("over");

}
