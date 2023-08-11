import std.stdio,
			 std.json,
			 std.conv : to;

import common,
			 tablemaker;

void main(string[] args){
	uint interval = 10;
	if (args.length > 2){
		try{
			interval = args[1].to!uint;
		} catch (Exception){
			stderr.writeln("args[1] is not uint, using default interval = " ~
					interval.to!string);
		}
	}
	char[] input;
	foreach (ubyte[] buf; chunks(stdin, 4096))
		input ~= cast(char[])buf;

	JSONValue[] timetables = parseJSON(input).get!(JSONValue[]);
	writeln(HTML_STYLE);
	foreach (classesJson; timetables){
		JSONValue[] classesJarr = classesJson.get!(JSONValue[]);
		Class[] classes = new Class[classesJarr.length];
		foreach (i, classJson; classesJarr)
			classes[i] = Class(classJson);
		writeln(generateTable(classes, interval));
	}
}
