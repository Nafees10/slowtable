module slowtable.filter;

import std.regex;

import slowtable.common;

/// set of filters
public struct Filters{
	/// relevant courses. null -> all relevant
	string[] coursesRel;
	/// relevant sections. null -> all relevant
	string[] sectionsRel;
	/// irrelevant courses
	string[] coursesNeg;
	/// irrelevant sections
	string[] sectionsNeg;
	/// relevant [section, course] combos
	string[2][] coursesSectionRel;
	/// irrelevant [section, course] combos
	string[2][] coursesSectionNeg;
}

/// Attempts to match a section course combo to Filters
///
/// Returns: true if matches, false if not
public bool matches(Filters filters, Class c){
	return matches(filters, c.section, c.name);
}

/// ditto
private bool matches(Filters filters, string section, string course){
	return
		(
		 matches(course, filters.coursesRel) ||
		 matches(section, filters.sectionsRel) ||
		 matches([section, course], filters.coursesSectionRel)
		) &&

		!matches(course, filters.coursesNeg) &&
		!matches(section, filters.sectionsNeg) &&
		!matches([section, course], filters.coursesSectionNeg);
}

/// Returns: true if a string matches in a list of patterns
private bool matches(string str, string[] patterns){
	foreach (pattern; patterns){
		if (matchFirst(str, pattern))
			return true;
	}
	return false;
}
/// ditto
private bool matches(size_t count)(
		string[count] strs, string[count][] patterns){
	foreach (pattern; patterns){
		bool match = true;
		static foreach (i; 0 .. count)
			match = match && matchFirst(strs[i], pattern[i]);
		if (match)
			return true;
	}
	return false;
}
