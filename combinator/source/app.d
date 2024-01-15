import std.stdio,
			 std.array,
			 std.string,
			 std.algorithm;

import common;

/// maximum number of courses this will let you generate combinations for
enum COURSES_LIMIT = 15; // what insane person wants this much?

void main(){
	Class[] classes;
	string[string] nameSec;
	while (!stdin.eof){
		string line = readln.chomp("\n");
		Class c;
		try {
			c = Class.deserialize(line);
		} catch (Exception) {
			continue;
		}
		classes ~= c;
		if (c.name in nameSec ||
				nameSec[c.name].canFind(c.section))
			continue;
		nameSec[c.name] ~= c.section;
	}
}

/// Generate all combinations.
Class[][] genComb(Class[] classes, string[string] nameSec){
	ClashMap clashes = ClashMap(classes);
	if (nameSec.length > COURSES_LIMIT)
		throw new Exception(
				"Refusing to generate combinations for that many courses");
	if (nameSec.keys.length){
		return genComb(classes, nameSec, clashes, 0);
	}
	return null;
}

Class[][] genComb(Class[] classes, string[string] nameSec,
		ClashMap clashes, uint index){
	static Set!string picks;
	immutable bool isLeaf = index + 1 == nameSec.keys.length;
	immutable string course = nameSec.keys[index];
	Class[][] ret;
	foreach (sec; nameSec[course]){
		immutable string selection = course ~ '-' ~ sec;
		if (clashes.clashes(picks, selection))
			continue;
		picks.add(selection);
		if (isLeaf)
			ret ~= subset(classes, picks);
		else
			ret ~= genComb(classes, nameSec, clashes, index + 1);
		picks.remove(selection);
	}
	return ret;
}

/// A Set of type `T`
struct Set(T){
	void[0][T] set;
	alias set this;
	void add(T val){
		set[val] = (void[0]).init;
	}
	bool exists(T val){
		return (val in set) !is null;
	}
	void remove(T val){
		set.remove(val);
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
			foreach (b; classes[i + 1 .. $]){
				if (a.overlaps(b))
					add(a.name, a.section, b.name, b.section);
			}
		}
	}

	/// Add a clashing pair of classes
	void add(string aName, string aSec, string bName, string bSec){
		sets[aName ~ '-' ~ aSec].add(bName ~ '-' ~ bSec);
	}

	/// Returns: whether a pair of classes clash
	bool clashes(string aName, string aSec, string bName, string bSec){
		return sets[aName ~ '-' ~ aSec].exists(bName ~ '-' ~ bSec) ||
			sets[bName ~ '-' ~ bSec].exists(aName ~ '-' ~ aSec);
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
