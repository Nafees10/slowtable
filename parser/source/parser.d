module parser;

import std.algorithm,
			 std.regex,
			 std.string,
			 std.conv,
			 std.datetime;

import ods;

import utils.misc : isAlphabet, isNum;

import common;

/// Parser for timetable
struct Parser{
private:
	/// sheet
	ODSSheet _sheet;
	/// Time scale for measuring start/end times
	TimeScale _scale;

	/// parses a row
	/// Returns: Class[], Classes found in that row
	Class[] _parseRow(string[] row, ref DayOfWeek day){
		Class[] ret;
		if (row.length < 2)
			return ret;
		if (tryReadDay(row[0], day) && day == DayOfWeek.sun)
			throw new Exception("nop, just no");
		string venue = row[1];
		enum Offset = 2;
		row = row[Offset .. $];
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
			sectionClass[1] = sectionClass[1].clean;
			Class c = Class(day,
					_scale.at(Offset + i),
					_scale.duration(Offset + i, count),
					sectionClass[1], sectionClass[0], venue);
			ret ~= c;
			i += count;
		}
		ret.classesSortByTime;
		return ret;
	}

public:
	/// Starting time
	TimeOfDay startTime;

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
		_scale = parseTimeScale(_sheet, startTime);
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
DayOfWeek readDay(string str) pure {
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
bool tryReadDay(string str, ref DayOfWeek day){
	try{
		day = readDay(str);
		return true;
	}catch (Exception e){
		return false;
	}
}
/// ditto
bool tryReadDay(string str){
	DayOfWeek dummy;
	return tryReadDay(str, dummy);
}

/// counts how many times, consecutive, the first element occurs
/// Returns: count, or 0 if array length 0
uint countConsecutive(T)(T[] array) pure {
	uint ret;
	foreach (elem; array){
		if (elem == array[0])
			ret ++;
		else
			break;
	}
	return ret;
}

/// Time scale
struct TimeScale{
	TimeOfDay start; /// starting time
	Duration[] add; /// how much to add at some index to get time covered
	/// Time at some index
	/// Returns: TimeOfDay at index
	TimeOfDay at(size_t index) const pure {
		TimeOfDay ret = start;
		foreach (a; add[0 .. min(index - 1, cast(ptrdiff_t)add.length - 1)])
			ret += a;
		return ret;
	}

	/// Duration from start till start+count
	/// Returns: Duration
	Duration duration(size_t start, size_t count){
		if (start >= add.length)
			return dur!"minutes"(0);
		uint ret;
		foreach (m; add[start .. min(add.length, start + count)])
			ret += m.total!"seconds";
		return dur!"seconds"(ret);
	}
}

/// Parses TimeScale from a ODSSheet
/// Throws: Exception if TimeScale looks bad
/// Returns: TimeScale
TimeScale parseTimeScale(ODSSheet sheet, TimeOfDay start){
	string[] mins;
	size_t hOffset = size_t.max;
	foreach (row; sheet){
		if (!row.length || row[0].strip != "Periods")
			continue;
		// look for the 10 minute mark
		foreach (i, cell; row){
			if (cell.strip == "10"){
				hOffset = i;
				break;
			}
		}
		if (row.length <= hOffset)
			throw new Exception("That's one messed up looking TimeScale");
		mins = row[hOffset .. $];
		sheet.popFront;
		break;
	}

	TimeScale ret;
	ret.start = start;
	ret.add.length = hOffset;
	ret.add[] = dur!"minutes"(0);
	uint prevMinutes = 0;
	foreach (i, minStr; mins){
		uint minutes;
		try{
			minutes = minStr.strip.to!uint;
		}catch (ConvException){
			continue;
		}
		ret.add ~= dur!"minutes"(
				minutes > prevMinutes
				? minutes - prevMinutes
				: minutes);
		prevMinutes = minutes;
	}
	return ret;
}
