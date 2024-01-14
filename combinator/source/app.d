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
	Set!string[string] set;
	pragma(inline, true) void add(
			string aName, string aSec, string bName, string bSec){
		set[aName ~ '-' ~ aSec].add(bName ~ '-' ~ bSec);
	}
	pragma(inline, true) bool clashes(
			string aName, string aSec, string bName, string bSec){
		return set[aName ~ '-' ~ aSec].exists(bName ~ '-' ~ bSec) ||
			set[bName ~ '-' ~ bSec].exists(aName ~ '-' ~ aSec);
	}

	this(Class[] classes){
		foreach (i, a; classes){
			foreach (b; classes[i + 1 .. $]){
				if (a.overlaps(b))
					add(a.name, a.section, b.name, b.section);
			}
		}
	}

	/// Returns: whether a course will clash with other picked courses
	bool clashes(Set!string picks, string name, string sec){
		immutable string cmp = name ~ '-' ~ sec;
		if (cmp !in set)
			return false;
		Set!string clashSet = set[cmp];
		foreach (key; clashSet.keys){
			if (picks.exists(key))
				return true;
		}
		return false;
	}
}
