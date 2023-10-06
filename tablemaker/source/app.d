import std.stdio,
			 std.string,
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

	Class[] classes;
	while (!stdin.eof){
		string line = readln.chomp("\n");
		Class c;
		try{
			c = Class.deserialize(line);
		} catch (Exception){
			continue;
		}
		classes ~= c;
	}
	writeln(HTML_STYLE);
	writeln(generateTable(classes, interval));
}
