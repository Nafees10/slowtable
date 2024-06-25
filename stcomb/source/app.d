import std.stdio,
			 std.conv,
			 std.math,
			 std.array,
			 std.string,
			 std.typecons,
			 std.bitmanip,
			 std.algorithm;

import core.stdc.stdlib : exit;

import utils.ds;

import common;

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
		immutable size_t courseCount = map.courseSids.length;
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
		foreach (Class a; tt){
			immutable size_t sidA = sids[tuple(a.name, a.section)];
			clashMatrix[sidA] = BitArray(
					new void[(sidCount + (size_t.sizeof - 1)) / size_t.sizeof],
					sidCount);
			foreach (Class b; tt){
				immutable size_t sidB = sids[tuple(b.name, b.section)];
				clashMatrix[sidA][sidB] = !a.overlaps(b);
			}
			// sid never clashes with itself
			clashMatrix[sidA][sidA] = true;
		}
	}

	/// Returns: whether a pair of sections clash
	bool clashes(size_t a, size_t b){
		return clashMatrix[a][b] == false;
	}
}

/// An iterator for sids, while excluding certain sids
struct SidIterator{
	private Tuple!(size_t, size_t)[] skip;
	private size_t curr = 0;
	private size_t len;
	@disable this();
	@property bool empty() pure const {
		return curr >= len;
	}
	/// `exclude` is sids to exclude
	this(ClassMap map, Set!size_t exclude) pure {
		Heap!(Tuple!(size_t, size_t), "a[0] < b[0]") heap;
		heap = new typeof(heap);
		foreach (sid; exclude.keys)
			heap.put(map.courseSids[map.names[sid][0]]);
		skip = heap.array;
		curr = 0;
		len = map.names.length;
		popFront();
	}

	size_t front() pure const {
		return curr;
	}

	void popFront() pure {
		if (empty) return;
		curr ++;
		while (skip.length){
			if (curr != skip[0][0])
				return;
			curr += skip[0][1];
			skip = skip[1 .. $];
		}
	}
}

/// A Node in the combinations tree
final class TreeNode{
public:
	ClassMap map;
	float[7] mt = 0; /// mean times for each day
	size_t[7] dc = 0; /// session counts for each day
	float dv = 0; /// sum of deviations from mean
	Set!size_t picks; /// picked sids

	this(TreeNode parent, ClassMap map, size_t pick){
		this.map = map;
		picks = Set!size_t(parent.picks.keys);
		mt = parent.mt;
		dv = parent.dv;
		picks.put(pick);
		// update dc
		foreach (Class c; map.sessions[pick]){
			immutable size_t time =
				c.time.second + 60 * (c.time.minute + (60 * c.time.hour));
			mt[c.day] = ((mt[c.day] * dc[c.day]) + time) / (dc[c.day] + 1);
			dc[c.day] ++;
		}
		// update dv
		foreach (Class c; map.sessions[pick]){
			immutable size_t time =
				c.time.second + 60 * (c.time.minute + (60 * c.time.hour));
			dv += abs(mt[c.day] - time);
		}
	}

	/// Returns: next nodes after this
	Heap!(TreeNode, "a.dv < b.dv") next(ClassMap map){
		Heap!(TreeNode, "a.dv < b.dv") heap;
		heap = new typeof(heap);
		foreach (size_t sid; SidIterator(map, picks))
			heap.put(new TreeNode(this, map, sid));
		return heap;
	}
}
