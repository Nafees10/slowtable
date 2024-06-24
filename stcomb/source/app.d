import std.stdio,
			 std.conv,
			 std.array,
			 std.string,
			 std.typecons,
			 std.bitmanip,
			 std.algorithm;

import core.stdc.stdlib;

import utils.ds;

import common,
			 rater;

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
		Timetable tt = Timetable.parse(stdin.byLineCopy);
		if (tt.classes is null)
			continue;
		ClassMap map = new ClassMap(tt);
	}
}

/// Maps courses/sections to continuous integers
final class ClassMap{
public:
	/// maps sid to set of clashing CourseSection(s)
	BitArray[] clashMatrix;

	/// maps names to sids
	size_t[Tuple!(string, string)] sids;
	/// maps course name to [sid_start, sid_count]
	Tuple!(size_t, size_t)[string] courseSids;

	/// maps sid to [courseName, sectionName]
	Tuple!(string, string)[] names;
	/// maps sid to Class[], sessions of this sid
	Class[][] sessions;

	/// constructor
	this(Timetable tt) pure {
		build(tt.classes);
	}
	/// ditto
	this (Class[] tt) pure {
		build(tt);
	}

	/// Resets this object
	void reset() pure {
		clashMatrix = null;
		sids = null;
		courseSids = null;
		names = null;
		sessions = null;
	}

	/// Builds this object from Class[].
	/// **Be sure to call `reset` on this before if not newly constructed**
	void build(Class[] tt) pure {
		// separate into courses and sections
		size_t sidCount;
		Class[][string][string] categ;
		foreach (Class c; tt){
			if (c.name !in categ)
				categ[c.name] = null;
			if (c.section !in categ[c.name]){
				categ[c.name][c.section] = null;
				sidCount ++;
			}
			categ[c.name][c.section] ~= c;
		}

		// build sids, courseSids, names, and sessions
		sessions.length = sidCount;
		names.length = sidCount;
		size_t sidNext;
		foreach (string course, Class[][string] sections; categ){
			courseSids[course] = tuple(sidNext, sections.length);
			foreach (string section, Class[] classes; sections){
				sids[tuple(course, section)] = sidNext;
				names[sidNext] = tuple(course, section);
				sessions[sidNext] = classes;
				sidNext ++;
			}
		}
		assert (sidNext == sidCount);

		/// build clashMatrix
		clashMatrix.length = sidCount;
		foreach (size_t sid, Class a; tt){
			clashMatrix[sid] = BitArray(
					new void[(sidCount + (size_t.sizeof - 1)) / size_t.sizeof],
					sidCount);
			foreach (size_t i, Class b; tt[])
				clashMatrix[sid][i] = !a.overlaps(b);
			// sid never clashes with itself
			clashMatrix[sid][sid] = true;
		}
	}

	/// Returns: whether a pair of sections clash
	bool clashes(size_t a, size_t b){
		return clashMatrix[a][b] == false;
	}
}

/// Stores rating for a combination
/// integers, one for each DayOfWeek
alias Rating = size_t[7];

/// Stores mean time for a combination, for each DayOfWeek
alias MeanTime = float[7];

/// A Node in the combinations tree
final class TreeNode{
public:
	size_t sid;
	TreeNode[] next;
}
