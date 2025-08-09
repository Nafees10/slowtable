module slowtable.combinator;

import slowtable.common;

import std.bitmanip,
			 std.algorithm,
			 std.typecons;

public import slowtable.combinator.base : Combinator, Combination;

/// generates combinations using a `Scorer` and `S` state (which a Scorer may
/// need)
/// Returns: range of `Combination!Scorer`
public auto combinations(Scorer, S...)(
		S state, BitArray[] clashMat, size_t[][] groupChoices){
	return Combinator!(Scorer, S)(state, clashMat, groupChoices).map!(n => n.view);
}

/// Maps (courses,sections) to continuous integers
final public class ClassMap{
public:
	/// Stores clash bits for each sid: `[sidA][sidB] == true` if no clash
	BitArray[] clashMatrix;

	/// number of section ids
	size_t sidCount;
	/// maps names to sids
	size_t[Tuple!(string, string)] sectionByName;
	/// maps cids to sids range for its course (start, count)
	/// picks range. i.e (start, count) for sids of same course
	Tuple!(size_t, size_t)[] courseSectionsRanges;
	/// maps sid to its cid
	size_t[] cidOfSid;

	/// maps sid to (courseName, sectionName)
	Tuple!(string, string)[] namesBySid;
	/// maps sid to Class[], sessions of this sid
	Class[][] sessionsBySection;

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
		sectionByName = null;
		courseSectionsRanges = null;
		cidOfSid = null;
		namesBySid = null;
		sessionsBySection = null;
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
		sessionsBySection.length = sidCount;
		cidOfSid.length = sidCount;
		namesBySid.length = sidCount;
		courseSectionsRanges.length = categ.keys.length;
		size_t sidNext;
		size_t courseI;
		foreach (string course, Class[][string] sections; categ){
			courseSectionsRanges[courseI] = tuple(sidNext, sections.keys.length);
			foreach (string section, Class[] classes; sections){
				sectionByName[tuple(course, section)] = sidNext;
				namesBySid[sidNext] = tuple(course, section);
				sessionsBySection[sidNext] = classes;
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
			immutable size_t sidA = sectionByName[tuple(a.name, a.section)];
			foreach (Class b; tt){
				immutable size_t sidB = sectionByName[tuple(b.name, b.section)];
				clashMatrix[sidA][sidB] = clashMatrix[sidA][sidB] && !a.overlaps(b);
			}
		}
		// sid always clashes with itself
		foreach (size_t sid; 0 .. sidCount)
			clashMatrix[sid][sid] = false;
	}
}
