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
	File input = stdin;//File("tt");
	ClassMap map = new ClassMap();
	if (args.canFind("--help") || args.canFind("-h")){
		writefln!"Usage:\n\t%s [maxCombinations]"(args[0]);
		exit(0);
	}

	size_t maxC = 200;
	if (args.length > 1){
		try{
			maxC = args[1].to!size_t;
		} catch (Exception e){
			stderr.writefln!"Expected integer for maxCombinations, found `%s`"(maxC);
			exit(1);
		}
	}

	while (!input.eof){
		Timetable tt = Timetable.parse(input.byLineCopy);
		if (tt.classes is null)
			continue;
		map.reset();
		map.build(tt.classes);

		size_t count = 0;
		foreach (TreeNode node; Combinator(new TreeNode(null, map))){
			writefln!"%s combination %d"(tt.name, count);
			foreach (size_t sid; node.picks.keys){
				foreach (Class c; node.map.sessions[sid])
					c.serialize.writeln();
			}
			writefln!"over";
			if (++count >= maxC)
				break;
		}
	}
}

/// Maps courses/sections to continuous integers
final class ClassMap{
public:
	/// maps sid to set of clashing CourseSection(s)
	BitArray[] clashMatrix;

	/// number of section ids
	size_t sidCount;
	/// maps names to sids
	size_t[Tuple!(string, string)] sids;
	/// maps sids to sids range for its course (start, count)
	/// picks range. i.e (start, count) for sids of same course
	Tuple!(size_t, size_t)[] cidsRange;

	/// maps sid to [courseName, sectionName]
	Tuple!(string, string)[] names;
	/// maps sid to Class[], sessions of this sid
	Class[][] sessions;

	/// constructor
	this(Timetable tt) {
		build(tt.classes);
	}
	/// ditto
	this (Class[] tt) {
		build(tt);
	}
	/// ditto
	this(){}

	/// Resets this object
	void reset() {
		sidCount = 0;
		clashMatrix = null;
		sids = null;
		cidsRange = null;
		names = null;
		sessions = null;
	}

	/// Builds this object from Class[].
	/// **Be sure to call `reset` on this before if not newly constructed**
	void build(Class[] tt) {
		// separate into courses and sections
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

		// build sids, sidsRange, names, and sessions
		sessions.length = sidCount;
		names.length = sidCount;
		cidsRange.length = categ.keys.length;
		size_t sidNext;
		size_t courseI;
		foreach (string course, Class[][string] sections; categ){
			cidsRange[courseI ++] = tuple(sidNext, sections.keys.length);
			foreach (string section, Class[] classes; sections){
				sids[tuple(course, section)] = sidNext;
				names[sidNext] = tuple(course, section);
				sessions[sidNext] = classes;
				sidNext ++;
			}
		}
		assert (sidNext == sidCount);

		clashMatrix.length = sidCount;
		foreach (size_t sid; 0 .. sidCount){
			clashMatrix[sid] = BitArray(
					new void[(sidCount + (size_t.sizeof - 1)) / size_t.sizeof],
					sidCount);
			clashMatrix[sid][] = true;
		}

		/// build clashMatrix
		foreach (Class a; tt){
			immutable size_t sidA = sids[tuple(a.name, a.section)];
			foreach (Class b; tt){
				immutable size_t sidB = sids[tuple(b.name, b.section)];
				clashMatrix[sidA][sidB] = clashMatrix[sidA][sidB] && !a.overlaps(b);
			}
		}
		// sid always clashes with itself
		foreach (size_t sid; 0 .. sidCount)
			clashMatrix[sid][sid] = false;
	}
}

/// An iterator for sids, while excluding certain sids
struct SidIterator{
	private const BitArray clash;
	private size_t curr;
	private size_t len;

	@disable this();
	this(const ClassMap map, size_t cid = 0,
			const BitArray clash = BitArray.init) {
		this.clash = clash;
		curr = size_t.max;
		Tuple!(size_t, size_t) range = map.cidsRange[cid];
		curr = range[0];
		len = curr + range[1];
		if (curr == 0)
			curr = size_t.max;
		else
			curr --;
		popFront();
	}

	@property bool empty() const {
		return curr >= len;
	}

	size_t front() const {
		return curr;
	}

	void popFront() {
		curr = curr == size_t.max ? 0 : curr + 1;
		if (empty) return;
		while (curr < len && clash[curr] == false)
			curr ++;
	}
}

/// A Node in the combinations tree
final class TreeNode{
private:
	Heap!(TreeNode, "a.score < b.score") _heap;
public:
	const ClassMap map;
	float[7] mt = 0; /// mean times for each day
	size_t[7] dc = 0; /// session counts for each day
	float dv = 0; /// sum of deviations from mean
	float score = 0; /// score used to determine how good this combination is
	Set!size_t picks; /// picked sids
	size_t cid; /// course id
	BitArray clash; /// clashes bit array

	this(const TreeNode parent, const ClassMap map, size_t pick = size_t.max) {
		this.map = map;
		if (parent){
			picks.put(parent.picks.keys);
			mt[] = parent.mt;
			dc[] = parent.dc;
			dv = parent.dv;
			clash = parent.clash.dup;
			cid = parent.cid == size_t.max ? 0 : parent.cid + 1;
		} else {
			cid = size_t.max;
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
		// count days, score = n(days) * dv
		immutable size_t days = (cast(size_t[])dc).map!(d => cast(ubyte)(d != 0)).sum;
		if (days)
			score = dv * days + (days << 16);
	}

	/// Returns: range of next nodes after this
	Heap!(TreeNode, "a.score < b.score") next() {
		if (_heap)
			return _heap;
		_heap = new typeof(_heap);
		size_t nextCid = cid == size_t.max ? 0 : cid + 1;
		if (nextCid >= map.cidsRange.length)
			return _heap;
		foreach (size_t sid; SidIterator(map, nextCid, clash))
			_heap.put(new TreeNode(this, map, sid));
		return _heap;
	}
}

struct Combinator{
	private Heap!(TreeNode, "a.score < b.score") frontier;
	@disable this();

	this(TreeNode root){
		frontier = new typeof(frontier);
		frontier.put(root);
		frontier.put(root);
		popFront;
	}

	@property void popFront(){
		frontier.popFront;
		while (!frontier.empty){
			TreeNode node = frontier.front;
			if (node.picks.keys.length == node.map.cidsRange.length)
				return;
			frontier.popFront;
			foreach (TreeNode next; node.next)
				frontier.put(next);
		}
	}

	@property TreeNode front(){
		return frontier.front;
	}

	@property bool empty(){
		return frontier.heap.length == 0;
	}
}
