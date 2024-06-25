import std.stdio,
			 std.conv,
			 std.math,
			 std.json,
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

		/*Set!size_t picks;
		picks.put(0);
		foreach (size_t sid; SidIterator(map, picks, map.clashMatrix[0]))
			stderr.writefln!"\t%d"(sid);*/

		print((new TreeNode(null, map)).next.array, tt.name);
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
	this(Timetable tt) /*pure*/ {
		build(tt.classes);
	}
	/// ditto
	this (Class[] tt) /*pure*/ {
		build(tt);
	}

	/// Resets this object
	void reset() /*pure*/ {
		clashMatrix = null;
		sids = null;
		courseSids = null;
		names = null;
		sessions = null;
	}

	/// Builds this object from Class[].
	/// **Be sure to call `reset` on this before if not newly constructed**
	void build(Class[] tt) /*pure*/ {
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
		}
		// sid always clashes with itself
		foreach (size_t sid; 0 .. sidCount)
			clashMatrix[sid][sid] = false;
	}

	/// Returns: whether a pair of sections clash
	bool clashes(size_t a, size_t b) /*pure*/ const {
		return clashMatrix[a][b] == false;
	}
}

/// An iterator for sids, while excluding certain sids
struct SidIterator{
	private Tuple!(size_t, size_t)[] skip;
	private const BitArray clash;
	private size_t curr = size_t.max;
	private size_t len;

	@disable this();
	this(const ClassMap map, const ref Set!size_t picks,
			const BitArray clash) /*pure*/ {
		this.clash = clash;
		Heap!(Tuple!(size_t, size_t), "a[0] < b[0]") heap;
		heap = new typeof(heap);
		foreach (size_t sid; picks.keys)
			heap.put(map.courseSids[map.names[sid][0]]);
		skip = heap.array;
		curr = size_t.max;
		len = map.names.length;
		popFront();
	}

	@property bool empty() /*pure*/ const {
		return curr >= len;
	}

	size_t front() /*pure*/ const {
		return curr;
	}

	void popFront() /*pure*/ {
		curr = curr == size_t.max ? 0 : curr + 1;
		if (empty) return;
		while (true){
			if (skip.length && curr == skip[0][0]){
				curr += skip[0][1];
				skip = skip[1 .. $];
				continue;
			}
			if (curr < clash.length && clash[curr] == false){
				curr ++;
				continue;
			}
			return;
		}
	}
}

/// A Node in the combinations tree
final class TreeNode{
private:
	Heap!(TreeNode, "a.dv < b.dv") _heap;
public:
	const ClassMap map;
	float[7] mt = 0; /// mean times for each day
	size_t[7] dc = 0; /// session counts for each day
	float dv = 0; /// sum of deviations from mean
	Set!size_t picks; /// picked sids
	BitArray clash; /// clashes bit array

	this(const TreeNode parent, const ClassMap map,
			size_t pick = size_t.max) /*pure*/ {
		this.map = map;
		if (parent){
			picks.put(parent.picks.keys);
			mt = parent.mt.dup;
			dc = parent.dc.dup;
			dv = parent.dv;
			clash = parent.clash.dup;
		} else {
			clash = BitArray(
					new void[(map.names.length + (size_t.sizeof - 1)) / size_t.sizeof],
					map.names.length);
			clash[] = true;
		}
		if (pick == size_t.max)
			return;
		clash &= map.clashMatrix[pick];
		picks.put(pick);

		// update mt and dc
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

	/// Returns: range of next nodes after this
	Heap!(TreeNode, "a.dv < b.dv") next() /*pure*/ {
		if (_heap)
			return _heap;
		_heap = new typeof(_heap);
		foreach (size_t sid; SidIterator(map, picks, clash)){
			_heap.put(new TreeNode(this, map, sid));
		}
		return _heap;
	}

	/// Returns: this as a json. Will result in a recursive `next()` call
	JSONValue jsonOf(size_t depth = size_t.max) /*pure*/ {
		JSONValue ret;
		//ret["mt"] = JSONValue(mt);
		//ret["dc"] = JSONValue(dc);
		ret["dv"] = JSONValue(dv);
		ret["picks"] = JSONValue(
				picks.keys
				.map!(p => map.names[p])
				.map!(p => p[0] ~ p[1])
				.array
				);
		if (depth == size_t.max)
			ret["next"] = JSONValue(next.map!(a => a.jsonOf).array);
		else if (depth)
			ret["next"] = JSONValue(next.map!(a => a.jsonOf(depth - 1)).array);
		return ret;
	}
}

void print(TreeNode[] nodes, string name){
	size_t count = 0;
	void print(TreeNode node){
		if (node.picks.keys.length == node.map.courseSids.length){
			writefln!"%s combination %d"(name, count ++);
			foreach (size_t sid; node.picks.keys){
				foreach (Class c; node.map.sessions[sid])
					c.serialize.writeln();
			}
			writefln!"over";
			/*if (count >= 200){
				stdout.flush; exit(0);
			}*/
			return;
		}

		foreach (next; node.next)
			print(next);
	}

	foreach (i, node; nodes){
		print(node);
	}
}
