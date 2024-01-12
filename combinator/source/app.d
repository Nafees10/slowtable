import std.stdio,
			 std.string;

import common;

void main(){
	Class[] classes;
	while (!stdin.eof){
		string line = readln.chomp("\n");
		Class c;
		try {
			c = Class.deserialize(line);
		} catch (Exception){
			continue;
		}
		classes ~= c;
	}
}
