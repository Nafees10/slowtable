import std.stdio,
			 std.path,
			 std.datetime,
			 std.conv : to;
import core.stdc.stdlib;

import parser, common;

void main(string[] args){
	string filename;
	uint sheetNumber;
	if (args.length < 2){
		stderr.writefln!"Usage:\n\t%s timetable.ods [sheetIndex]"(args[0]);
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
	writefln!"%s[%d]"(filename.baseName, sheetNumber);
	try{
		foreach (Class c; Parser(filename, sheetNumber, TimeOfDay(8, 0)))
			writeln(c.serialize);
	} catch (Exception e){
		stderr.writeln(e.msg);
		exit(1);
	}
	writeln("over");

}
