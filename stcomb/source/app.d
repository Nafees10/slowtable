import std.stdio,
			 std.conv,
			 std.array,
			 std.string,
			 std.algorithm;

import core.stdc.stdlib;

import utils.ds;

import common,
			 rater;

/// maximum number of courses this will let you generate combinations for
enum COURSES_LIMIT = 15; // what insane person wants this much?

void main(string[] args){
	if (args.canFind("-h") || args.canFind("--help")){
		writeln("Usage:\n\t", args[0], " consistencyWeight daysWeight gapsWeight");
		writeln("Weights are all integer, and by default, 1");
		exit(1);
	}
	uint[3] weights = 1;
	foreach (i, arg; args[1 .. $]){
		try{
			weights[i] = arg.to!uint;
		} catch (Exception e){
			stderr.writefln!"`%s` is not a valid weight"(arg);
		}
	}

	while (!stdin.eof){
		string line = readln.chomp("\n");
		if (line.length == 0) continue;
		immutable string name = line;
		Class[] classes;
		string[][string] nameSec;

		while (!stdin.eof){
			line = readln.chomp("\n");
			if (line == "over")
				break;
			Class c;
			try {
				c = Class.deserialize(line);
			} catch (Exception) {
				continue;
			}
			classes ~= c;
			if (c.name in nameSec &&
					nameSec[c.name].canFind(c.section))
				continue;
			nameSec[c.name] ~= c.section;
		}
	}
}

/// Returns: a subset of timetable, containing only set classes sections
Class[] subset(Class[] classes, Set!string set){
	return classes.filter!(c => set.exists(c.name ~ '-' ~ c.section)).array;
}

/// Stores overlap info about classes
struct ClashMap{
	Set!string[string] sets;

	/// constructor
	this(Class[] classes){
		foreach (i, a; classes){
			foreach (b; classes){
				if (a.overlaps(b))
					add(a.name, a.section, b.name, b.section);
			}
		}
	}

	/// Add a clashing pair of classes
	void add(string aName, string aSec, string bName, string bSec){
		immutable string key = aName ~ '-' ~ aSec;
		if (key !in sets)
			sets[key] = Set!string.init;
		sets[aName ~ '-' ~ aSec].put(bName ~ '-' ~ bSec);
	}

	/// Returns: whether a pair of classes clash
	bool clashes(string aName, string aSec, string bName, string bSec){
		immutable a = aName ~ '-' ~ aSec, b =  bName ~ '-' ~ bSec;
		return (a in sets && sets[a].exists(b)) || (b in sets && sets[b].exists(a));
	}

	/// Returns: whether a course will clash with other picked courses
	bool clashes(Set!string picks, string name, string sec){
		return clashes(picks, name ~ '-' ~ sec);
	}
	/// ditto
	bool clashes(Set!string picks, string cmp){
		if (cmp !in sets)
			return false;
		Set!string clashSet = sets[cmp];
		foreach (key; clashSet.keys){
			if (picks.exists(key))
				return true;
		}
		return false;
	}
}
