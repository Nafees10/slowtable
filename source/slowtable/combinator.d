module slowtable.combinator;

import std.stdio,
			 std.conv,
			 std.math,
			 std.array,
			 std.range,
			 std.string,
			 std.typecons,
			 std.bitmanip,
			 std.algorithm;

import core.stdc.stdlib : exit;

import utils.ds;

import slowtable.common;

/// Maps (courses,sections) to continuous integers
final class ClassMap{
public:
	/// Stores clash bits for each sid: `[sidA][sidB] == true` if no clash
	BitArray[] clashMatrix;

	/// number of section ids
	size_t sidCount;
	/// maps names to sids
	size_t[Tuple!(string, string)] sidByName;
	/// maps cids to sids range for its course (start, count)
	/// picks range. i.e (start, count) for sids of same course
	Tuple!(size_t, size_t)[] cidsRange;
	/// maps sid to its cid
	size_t[] cidOfSid;

	/// maps sid to (courseName, sectionName)
	Tuple!(string, string)[] namesBySid;
	/// maps sid to Class[], sessions of this sid
	Class[][] sessionsBySid;

	/// constructor
	this(Timetable tt) pure {
		build(tt.classes);
	}
	/// ditto
	this (Class[] tt) pure {
		build(tt);
	}
	/// ditto
	this() pure {}

	/// Resets this object
	void reset() pure {
		sidCount = 0;
		clashMatrix = null;
		sidByName = null;
		cidsRange = null;
		cidOfSid = null;
		namesBySid = null;
		sessionsBySid = null;
	}

	/// Builds this object from Class[].
	/// **Be sure to call `reset` on this before if not newly constructed**
	void build(Class[] tt) pure {
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
		sessionsBySid.length = sidCount;
		cidOfSid.length = sidCount;
		namesBySid.length = sidCount;
		cidsRange.length = categ.keys.length;
		size_t sidNext;
		size_t courseI;
		foreach (string course, Class[][string] sections; categ){
			cidsRange[courseI] = tuple(sidNext, sections.keys.length);
			foreach (string section, Class[] classes; sections){
				sidByName[tuple(course, section)] = sidNext;
				namesBySid[sidNext] = tuple(course, section);
				sessionsBySid[sidNext] = classes;
				cidOfSid[sidNext] = courseI;
				sidNext ++;
			}
			courseI ++;
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
			immutable size_t sidA = sidByName[tuple(a.name, a.section)];
			foreach (Class b; tt){
				immutable size_t sidB = sidByName[tuple(b.name, b.section)];
				clashMatrix[sidA][sidB] = clashMatrix[sidA][sidB] && !a.overlaps(b);
			}
		}
		// sid always clashes with itself
		foreach (size_t sid; 0 .. sidCount)
			clashMatrix[sid][sid] = false;
	}
}

/// Default scoring system
/// Optimizes for:
/// - least number of days
/// - classes closest together
struct ScoreDev{
	private float[7] mt = 0; /// mean times for each day
	private size_t[7] dc = 0; /// session counts for each day
	private float dv = 0; /// sum of deviations from mean
	public float score = 0; /// score used to determine how good this combination is

	this(const ClassMap map, const typeof(this) parent, size_t pick) {
		mt[] = parent.mt;
		dc[] = parent.dc;
		dv = parent.dv;
		// update mt and dc
		foreach (Class c; map.sessionsBySid[pick]){
			immutable size_t time =
				c.time.second + 60 * (c.time.minute + (60 * c.time.hour));
			mt[c.day] = ((mt[c.day] * dc[c.day]) + time) / (dc[c.day] + 1);
			dc[c.day] ++;
		}
		// update dv
		foreach (Class c; map.sessionsBySid[pick]){
			immutable size_t time =
				c.time.second + 60 * (c.time.minute + (60 * c.time.hour));
			dv += abs(mt[c.day] - time);
		}
		// count days, score = n(days) * dv
		immutable size_t days =
			(cast(size_t[])dc).map!(d => cast(ubyte)(d != 0)).sum;
		if (days)
			score = dv * days + (days << 16);
	}
}

/// A Node in the combinations tree
final class Node(Score) if (is (Score == struct)){
private:
	const ClassMap _map;
	Heap!(Node!Score, "a.score.score < b.score.score") _next;
	const size_t[][] _sids; /// selection options
	BitArray _clash; /// clashes bit array
public:
	Set!size_t picks; /// picked sids
	Score score; /// score

	this(const ClassMap map, size_t[][] sids) pure {
		_map = map;
		_sids = sids;
		_clash = BitArray(
				new void[(map.sidCount + (size_t.sizeof - 1)) / size_t.sizeof],
				map.sidCount);
		_clash[] = true;
	}

	this(const Node parent, size_t pick) {
		_map = parent._map;
		_sids = parent._sids[1 .. $];
		_clash = parent._clash.dup;
		_clash &= _map.clashMatrix[pick];
		picks.put(parent.picks.keys);
		picks.put(pick);
		score = Score(_map, parent.score, pick);
		// clash with entire course
		immutable Tuple!(size_t, size_t) range = _map.cidsRange[_map.cidOfSid[pick]];
		foreach (size_t sid; iota(range[0], range[1]))
			_clash &= _map.clashMatrix[sid];
	}

	/// Returns: range of next nodes after this
	Heap!(Node, "a.score.score < b.score.score") next() {
		if (_next)
			return _next;
		_next = new typeof(_next);
		if (_sids.length == 0 || _sids[0].length == 0)
			return _next;
		foreach (size_t sid; _sids[0].filter!(s => _clash[s] == true))
			_next.put(new Node!Score(this, sid));
		return _next;
	}
}

/// Range of Timetable combinations, best scoring one first
struct Combinator(Score) if (is (Score == struct)){
	private Heap!(Node!Score, "a.score.score < b.score.score") frontier;
	private size_t[][] _sids;
	@disable this();

	this(const ClassMap map, size_t[][] sids){
		Node!Score node = new Node!Score(map, sids);
		_sids = sids;
		frontier = new typeof(frontier);
		frontier.put(node);
		frontier.put(node);
		popFront();
	}

	@property void popFront(){
		frontier.popFront;
		while (!frontier.empty){
			Node!Score node = frontier.front;
			if (node.picks.keys.length == _sids.length)
				return;
			frontier.popFront;
			foreach (Node!Score next; node.next)
				frontier.put(next);
		}
	}

	@property Node!Score front(){
		return frontier.front;
	}

	@property bool empty(){
		return frontier.heap.length == 0;
	}
}
