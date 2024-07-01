module app.stdelab;

import std.stdio,
			 std.string;

import slowtable.common;

void stdelab_main(string[]){
	while (!stdin.eof){
		string line = readln.chomp("\n");
		if (line.length == 0) continue;
		writeln(line); // print name back

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
			if (c.name.length >= 3 && c.name[$ - 3 .. $] == "lab"){
				c.name.length -= 3;
				c.name = c.name.clean;
				ptrdiff_t index = c.section.indexOf(",");
				if (index > 0)
					c.section = c.section[0 .. index];
				index = cast(ptrdiff_t)c.section.length - 1;
				while (index > 0 && c.section[index .. $].isNumeric)
					index --;
				c.section = c.section[0 .. index + 1];
			}
			c.serialize.writeln;
		}
		writeln("over");
	}
}
