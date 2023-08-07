module parser;

import std.algorithm,
			 std.regex,
			 std.string,
			 std.datetime,
			 std.conv,
			 std.json;

import ods;

import utils.misc : isAlphabet, isNum;

/// Stores information about a single class session
struct Class{
	/// day this occurs
	DayOfWeek day;
	/// when
	TimeOfDay time;
	/// duration
	Duration duration;
	/// course name
	string name;
	/// section
	string section;
	/// venue
	string venue;

	/// Returns: string representation as `{name section venue (day, start-end)}`
	string toString() const {
		return format!"{%s %s %s (%s, %s-%s)}"(
				name, section, venue, day, time, time + duration);
	}

	/// encode's time for comparison, for a Class
	///
	/// Returns: encoded time
	@property uint timeEncode() const {
		uint ret;
		ret = day << 20;
		ret |= (dur!"hours"(time.hour) + dur!"minutes"(time.minute) +
			dur!"seconds"(time.second)).total!"seconds";
		return ret;
	}

	JSONValue toJSON() const {
		JSONValue ret;
		ret["day"] = JSONValue(day.to!string);
		ret["time"] = JSONValue(time.toString);
		ret["duration"] = JSONValue(duration.total!"minutes");
		ret["name"] = JSONValue(name);
		ret["section"] = JSONValue(section);
		ret["venue"] = JSONValue(venue);
		return ret;
	}
}

unittest{
	Class c = Class(DayOfWeek.mon, TimeOfDay(8, 0), dur!"minutes"(120),
			"Programming", "BSE-4A", "CS-1");
	assert(c.to!string == "{Programming BSE-4A CS-1 (mon, 08:00:00-10:00:00)}");
	Class a, b;
	foreach (day; DayOfWeek.mon .. DayOfWeek.sat){
		foreach (hour; 0 .. 24){
			foreach (min; 0 .. 60){
				a.time = TimeOfDay(hour, min);
				a.day = day;
				assert(a.timeEncode > b.timeEncode);
				b = a;
			}
		}
	}
}

/// Sorts classes by time
void sortByTime(ref Class[] classes){
	classes.sort!"a.timeEncode < b.timeEncode";
}

/// Sorts classes by venue and day
Class[][string][DayOfWeek] sortByDayVenueTime(Class[] classes){
	Class[][string][DayOfWeek] ret;
	foreach (c; classes)
		ret[c.day][c.venue] ~= c;
	foreach (day, dayClasses; ret){
		foreach (venue, ref venueClasses; dayClasses){
			venueClasses.sortByTime;
		}
	}
	return ret;
}

/// Finds earliest starting time, and latest ending time
/// Returns: [starting time, ending time]
TimeOfDay[2] timeMinMax(Class[] classes){
	TimeOfDay min = TimeOfDay.max, max = TimeOfDay.min;
	foreach (c; classes){
		if (c.time < min)
			min = c.time;
		if (c.time + c.duration > max)
			max = c.time + c.duration;
	}
	return [min, max];
}

/// Separates section from course.
/// Returns: [section, course], string array length 2
string[2] separateSectionCourse(string str) pure {
	const int start = cast(int)str.indexOf('('), end = cast(int)str.indexOf(')');
	if (start < 0 || end <= start)
		return [null, str];
	return [str[start + 1 .. end].strip, str[0 .. start].strip];
}
/// ditto
string[2][] separateSectionCourse(string[] str) pure {
	string[2][] ret;
	ret.length = str.length;
	foreach (i, s; str)
		ret[i] = separateSectionCourse(s);
	return ret;
}

/// Parser for timetable
class Parser{
private:
	/// sheet
	ODSSheet _sheet;

	/// parses a row
	/// Returns: Class[], Classes found in that row
	Class[] _parseRow(string[] row, ref DayOfWeek day){
		Class[] ret;
		if (row.length < 2)
			return ret;
		if (tryReadDay(row[0], day) && day == DayOfWeek.sun)
			throw new Exception("nop, just no");
		string venue = row[1];
		row = row[2 .. $];
		for (uint i = 0; i < row.length;){
			if (row[i] == ""){
				i ++;
				continue;
			}
			const uint count = countConsecutive(row[i .. $]);
			if (!count)
				break;
			string[2] sectionClass = separateSectionCourse(row[i]);
			if (!sectionClass[1].length){
				i += count;
				continue;
			}
			Class c = Class(day, TimeOfDay(8,0) + (colDur * i) + timeOffset,
					colDur * count, sectionClass[1], sectionClass[0],venue);
			ret ~= c;
			i += count;
		}
		return ret;
	}

public:
	/// time offset  (added to class start time)
	Duration timeOffset;
	/// Duration per column
	Duration colDur;
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

	/// constructor
	this (string filename, uint sheet = 0){
		_sheet = new ODSSheet();
		_sheet.repeatMergedCells = true;
		_sheet.readSheet(filename, sheet);
	}
	~this(){
		.destroy(_sheet);
	}

	/// Parses the sheet for Class[]
	Class[] parse(){
		Class[] ret;
		// find monday
		string[] row;
		while ((row.length < 2 || !tryReadDay(row[0])) && !_sheet.empty){
			row = _sheet.front;
			_sheet.popFront;
		}
		DayOfWeek day;
		if (row.length < 2 || !tryReadDay(row[0], day))
			return ret;
		do{
			ret ~= _parseRow(row, day);
			row = _sheet.front;
			_sheet.popFront;
		} while (!_sheet.empty);
		return ret;
	}
}

/// Finds DayOfWeek from sheet string
/// Returns: DayOfWeek
/// Throws: Exception if not found
private DayOfWeek readDay(string str) pure {
	if (str.canFind("Monday"))
		return DayOfWeek.mon;
	if (str.canFind("Tuesday"))
		return DayOfWeek.tue;
	if (str.canFind("Wednesday"))
		return DayOfWeek.wed;
	if (str.canFind("Thursday"))
		return DayOfWeek.thu;
	if (str.canFind("Friday"))
		return DayOfWeek.fri;
	if (str.canFind("Saturday"))
		return DayOfWeek.sat;
	if (str.canFind("Sunday"))
		return DayOfWeek.sun;
	throw new Exception ("Failed to detect day");
}

/// Returns: true if readDay was successful
private bool tryReadDay(string str, ref DayOfWeek day){
	try{
		day = readDay(str);
		return true;
	}catch (Exception e){
		return false;
	}
}
/// ditto
private bool tryReadDay(string str){
	DayOfWeek dummy;
	return tryReadDay(str, dummy);
}

/// counts how many times, consecutive, the first element occurs
/// Returns: count, or 0 if array length 0
private uint countConsecutive(T)(T[] array) pure {
	uint ret;
	foreach (elem; array){
		if (elem == array[0])
			ret ++;
		else
			break;
	}
	return ret;
}
