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

	while (!stdin.eof){
		string line = readln.chomp("\n");
		if (line.length == 0) continue;
		writeln(HTML_STYLE);
		writefln!"<h1>%s:</h1>"(line); // print name back

		Class[] classes;
		while (!stdin.eof){
			line = readln.chomp("\n");
			if (line == "over")
				break;
			Class c;
			try{
				c = Class.deserialize(line);
			} catch (Exception){
				continue;
			}
			classes ~= c;
		}
		writeln(generateTable(classes, interval));
		writeln("<hr>");
	}
}
