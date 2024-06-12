import std.stdio,
			 std.conv,
			 std.array,
			 std.string,
			 std.typecons,
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
		Timetable tt = Timetable.parse(stdin.byLineCopy);
		if (tt.classes is null)
			continue;
	}
}

alias CourseSection = Tuple!(size_t, "cId", size_t, "sId");

/// Maps courses/sections to continuous integers
struct ClassMap{
	size_t[string] cId; /// maps names to ids
	size_t[string][string] sId; /// maps names to map of sections to ids
	string[] courses; /// maps ids to names
	string[][] sections; /// maps ids to sections of course ids
	Class[][][] sessions; /// sessions for each section id of each course id

	/// Returns: CourseSection against a section name and section
	CourseSection conv(string name, string section) const pure {
		CourseSection ret;
		if (name !in cId || name !in sId || section !in sId[name])
			throw new Exception(format!"%s-%s not found in ClassMap"(name, section));
		ret.cId = cId[name];
		ret.sId = sId[name][section];
		return ret;
	}

	/// ditto
	CourseSection conv(ref const Class c) const pure {
		return conv(c.name, c.section);
	}

	/// Returns: tuple(courseName, sectionName) from a CourseSection
	Tuple!(string, string) conv(CourseSection cs) const pure {
		if (cs.cId > courses.length || cs.sId > sections[cs.cId].length)
			throw new Exception("CourseSection out of bounds in ClassMap");
		return tuple(courses[cs.cId], sections[cs.cId][cs.sId]);
	}

	@disable this();
	this(Class[] tt) pure {
		foreach (Class c; tt){
			if (c.name !in cId){
				cId[c.name] = courses.length;
				courses ~= c.name;
				sId[c.name] = null;
				sections ~= null;
			}
			immutable size_t courseId = cId[c.name];
			if (c.section !in sId[c.name]){
				sId[c.name][c.section] = sections[courseId].length;
				sections[courseId] ~= c.section;
			}
			immutable size_t sectionId = sId[c.name][c.name];
			sessions[courseId][sectionId] ~= c;
		}
	}
	this(Timetable tt) pure {
		this(tt.classes);
	}
}

/// Stores overlap info about classes
struct ClashMap{
	/// maps CourseSection to set of clashing CourseSection(s)
	Set!CourseSection[CourseSection] clashSets;
	/// tuples of clashing pairs of CourseSections
	Set!(Tuple!(CourseSection, CourseSection)) clashPairs;

	/// constructor
	this(Class[] classes, ref const ClassMap map) pure {
		foreach (i, Class a; classes){
			foreach (Class b; classes){
				if (!a.overlaps(b))
					continue;
				add(map.conv(a), map.conv(b));
			}
		}
	}

	/// Add a clashing pair of classes
	void add(CourseSection a, CourseSection b) pure {
		if (a !in clashSets)
			clashSets[a] = Set!CourseSection.init;
		clashSets[a].put(b);
		if (b !in clashSets)
			clashSets[b] = Set!CourseSection.init;
		clashSets[b].put(a);

		if (tuple(a, b) !in clashPairs)
			clashPairs.put(tuple(a, b));
		if (tuple(b, a) !in clashPairs)
			clashPairs.put(tuple(b, a));
	}

	/// Returns: whether a pair of classes clash
	bool clashes(CourseSection a, CourseSection b){
		return a in clashSets && clashSets[a].exists(b);
	}
	// TODO: continue from here
}
