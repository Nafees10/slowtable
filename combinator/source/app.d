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
		} catch (Exception) {
			continue;
		}
		classes ~= c;
	}
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
		immutable string cmp = name ~ '-' ~ sec;
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
