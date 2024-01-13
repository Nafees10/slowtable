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

struct ClashMap{
	void[0][string][string] set;
	alias set this;
	pragma(inline, true) void add(
			string aName, string aSec, string bName, string bSec){
		set[aName ~ '-' ~ aSec][bName ~ '-' ~ bSec] = (void[0]).init;
	}
	pragma(inline, true) bool clashes(
			string aName, string aSec, string bName, string bSec){
		return (bName ~ '-' ~ bSec) !in set[aName ~ '-' ~ aSec];
	}

	this(Class[] classes){
		foreach (i, a; classes){
			foreach (j, b; classes){
				if (i == j) continue;
				if (a.overlaps(b))
					add(a.name, a.section, b.name, b.section);
			}
		}
	}
}
