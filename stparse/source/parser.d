module parser;

import std.algorithm,
			 std.regex,
			 std.string,
			 std.conv,
			 std.datetime;

import ods;

import utils.misc : isAlphabet, isNum;

import common;

private enum Offset = 2;

/// Parser for timetable
struct Parser{
private:
	/// sheet
	ODSSheet _sheet;
	/// Time scale for measuring start/end times
	TimeScale _scale;
	/// current row
	string[] _row = null;
	/// index in current row
	size_t _rowInd = 0;
	/// Current day
	DayOfWeek _day;

	/// parses next class in row
	Class _parseClass(){
		if (_rowInd == 0){
			if (_row.length <= 2){
				_row = null;
				return Class.init;
			}
			tryReadDay(_row[0], _day);
			_rowInd = 2;
		}
		// skip spaces
		while (_rowInd < _row.length && _row[_rowInd] == "")
			++ _rowInd;
		if (_rowInd >= _row.length){
			_row = null;
			return Class.init;
		}

		const uint count = countConsecutive(_row[_rowInd .. $]);
		if (!count){
			_row = null;
			return Class.init;
		}
		string[2] secClass = separateSectionCourse(_row[_rowInd]);
		Class ret = Class(_day,
				_scale.at(_rowInd),
				_scale.duration(_rowInd, count),
				secClass[1].clean, secClass[0], _row[1]
				);
		_rowInd += count;
		return ret;
	}

public:
	Class front;

	/// constructor
	this (string filename, uint sheet = 0, TimeOfDay startTime){
		_sheet = new ODSSheet();
		_sheet.repeatMergedCells = true;
		_sheet.readSheet(filename, sheet);
		_scale = parseTimeScale(_sheet, startTime);
		// find monday
		_row = _sheet.front;
		while ((_row.length < 2 || !tryReadDay(_row[0], _day)) && !_sheet.empty){
			_sheet.popFront;
			_row = _sheet.front;
		}
		_rowInd = 0;
		popFront();
	}
	~this(){
		.destroy(_sheet);
	}

	bool empty(){
		return _row == null && _sheet.empty;
	}

	void popFront(){
		while (true){
			if (_row == null){
				if (_sheet.empty)
					return;
				_sheet.popFront;
				_row = _sheet.front;
				_rowInd = 0;
			}
			front = _parseClass();
			if (_row == null)
				continue;
			if (_rowInd >= _row.length)
				_row = null;
			break;
		}
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
