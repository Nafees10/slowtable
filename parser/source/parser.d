module slowtable.parser;

import std.algorithm,
			 std.regex,
			 std.string,
			 std.datetime;

import ods;

import utils.misc : isAlphabet, isNum;

import common;

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
			sectionClass[1] = sectionClass[1].courseNameClean;
			Class c = Class(day, TimeOfDay(8,0) + (colDur * i) + timeOffset,
					colDur * count, sectionClass[1], sectionClass[0],venue);
			ret ~= c;
			i += count;
		}
		ret.classesSortByTime;
		return ret;
	}

public:
	/// time offset  (added to class start time)
	Duration timeOffset;
	/// Duration per column
	Duration colDur;

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

/// Cleans up course name
/// removes non-alphanumeric characters, minimizes spaces to maximum 1,
/// lowercases
/// Returns: clean name
private string courseNameClean(string course){
	string ret;
	for (uint i = 0; i < course.length; i ++){
		if (isAlphabet(course[i .. i + 1]) || isNum(course[i .. i + 1], false)){
			ret ~= course[i] + (32 * (course[i] >= 'A' && course[i] <= 'Z'));
			continue;
		}
		if (course[i] == ' '){
			ret ~= ' ';
			while (i + 1 < course.length && course[i + 1] == ' ')
				i ++;
		}
	}
	return ret.strip;
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

/// Separates section from course.
/// Returns: [section, course], string array length 2
private string[2] separateSectionCourse(string str) pure {
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

// new parser
/*import std.algorithm,
			 std.regex,
			 std.string,
			 std.datetime,
			 std.conv,
			 std.json;

import ods;

import utils.misc : isAlphabet, isNum;

/// An entry in the sheet and its location
struct Entry{
	/// starting cell index
	size_t index;
	/// width
	size_t width;
	/// ending index (last index occupied by this)
	@property size_t lastIndex() const pure {
		return index + width - 1;
	}
	/// name
	string name;
}

/// Time scale
struct TimeScale{

}

Entry[] parseEntries(string[] row){
	Entry[] ret;
	for (size_t i = 0; i < row.length;){
		size_t count = 1;
		while (i + count < row.length && row[i + count] == row[i])
			++count;
		ret ~= Entry(i, count, row[i]);
		i += count;
	}
	return ret;
}

/// Locates starting point of time scale
/// Returns: [rowIndex, colIndex]
size_t[2] locateScale(Entry[][] sheet){
	throw new Exception("Not implemented");
}*/
