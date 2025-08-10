module slowtable.common;

import std.algorithm,
			 std.typecons,
			 std.bitmanip,
			 std.datetime,
			 std.format,
			 std.string,
			 std.array,
			 std.range,
			 std.conv,
			 std.uni;

/// Stores information about a single class session
public struct Class{
	/// day this occurs
	DayOfWeek day;
	/// when
	TimeOfDay time;
	/// duration
	Duration duration;

	/// duration in seconds
	@property duration_s() const pure {
		return duration.total!"seconds";
	}
	@property duration_s(size_t dur) pure {
		return duration = dur.dur!"seconds";
	}

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

	/// Serializes into a tab separated line
	/// `name section venue day time duration(minutes)`
	string serialize() const {
		return format!"\t%s\t%s\t%s\t%s\t%s\t%d"(
				name, section, venue, day, time.toISOString, duration.total!"minutes");
	}

	/// Deserialize from a tab separated line
	/// Throws: Exception when invalid format
	/// Returns: deserialized Class
	static Class deserialize(string line) pure {
		string[] vals = line.split("\t");
		if (vals.length && vals[0].length == 0)
			vals = vals[1 .. $];
		if (vals.length != 6)
			throw new Exception("Invalid format");
		Class ret;
		try{
			ret.name = vals[0];
			ret.section = vals[1];
			ret.venue = vals[2];
			ret.day = vals[3].to!DayOfWeek;
			ret.time = TimeOfDay.fromISOString(vals[4]);
			ret.duration = dur!"minutes"(vals[5].to!uint);
		} catch (Exception){
			throw new Exception("Invalid format");
		}
		return ret;
	}

	/// Removes `" lab"` from end of name if present, and adjusts section
	void delab() pure {
		if (name.length < 3 || name[$ - 3 .. $] != "lab")
			return;
		name.length -= 3;
		name = name.nameClean;
		ptrdiff_t index = section.indexOf(",");
		if (index > 0)
			section = section[0 .. index];
		index = cast(ptrdiff_t)section.length - 1;
		while (index > 0 && section[index .. $].isNumeric)
			index --;
		section = section[0 .. index + 1];
	}

	/// encode's time for comparison, for a Class
	///
	/// Returns: encoded time
	@property uint timeEncode() pure const {
		uint ret;
		ret = day << 20;
		ret |= (dur!"hours"(time.hour) + dur!"minutes"(time.minute) +
			dur!"seconds"(time.second)).total!"seconds";
		return ret;
	}

	this (DayOfWeek day, TimeOfDay time, Duration duration, string name,
			string section, string venue) pure {
		this.day = day;
		this.time = time;
		this.duration = duration;
		this.name = name;
		this.section = section;
		this.venue = venue;
	}
}

///
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
	JSONValue json = c.jsonOf;
	Class d = Class(json);
	assert (d.day == c.day);
	assert (d.time == c.time);
	assert (d.duration == c.duration);
	assert (d.name == c.name);
	assert (d.section == c.section);
	assert (d.venue == c.venue);

	d = Class.deserialize(c.serialize);
	assert (d.day == c.day);
	assert (d.time == c.time);
	assert (d.duration == c.duration);
	assert (d.name == c.name);
	assert (d.section == c.section);
	assert (d.venue == c.venue);
}

/// A timetable (collection of Classes)
public struct Timetable{
	string name;
	Class[] classes;

	/// parses timetable from a input range
	static Timetable parse(Range)(Range input)
			if (isInputRange!Range && is (ElementType!Range == string)){
		Timetable ret;
		foreach (line; input){
			if (line == "over")
				continue;
			if (ret.name is null && line.length && line[0] != '\t'){
				ret.name = line;
				continue;
			}
			try{
				Class c = Class.deserialize(line.chomp("\n").idup);
				ret.classes ~= c;
			} catch (Exception){}
		}
		return ret;
	}
}

/// Sorts classes by time
public void sortByTime(ref Class[] classes){
	classes.sort!"a.timeEncode < b.timeEncode";
}

/// Sorts classes by venue and day
public Class[][string][DayOfWeek] sortByVenueDay(Class[] classes) pure {
	Class[][string][DayOfWeek] ret;
	foreach (c; classes)
		ret[c.day][c.venue] ~= c;
	return ret;
}

/// Finds earliest starting time, and latest ending time
/// Returns: [starting time, ending time]
public TimeOfDay[2] timeMinMax(Class[] classes) pure {
	TimeOfDay min = TimeOfDay.max, max = TimeOfDay.min;
	foreach (c; classes){
		if (c.time < min)
			min = c.time;
		if (c.time + c.duration > max)
			max = c.time + c.duration;
	}
	return [min, max];
}

/// checks if timings (time, duration, day) of two Class coincideds. Does not
/// check venue
///
/// Returns: true if clashes
public bool overlaps(Class a, Class b) pure {
	return a.day == b.day &&
		a.time < b.time + b.duration && b.time < a.time + a.duration;
}

/// Cleans up a name/section string
/// Returns: cleaned up string
public string nameClean(string str) pure {
	str = str.strip;
	string ret;
	bool white = false;
	foreach (c; str){
		if (c.isWhite || !c.isAlphaNum){
			white = true;
			continue;
		}
		if (white){
			white = false;
			ret ~= ' ';
		}
		ret ~= c.toLower;
	}
	return ret;
}
///
unittest{
	assert("  \tbla \t \n- bla-bla   \t  \n ".nameClean == "bla bla bla");
}

/// Separates section from course.
/// Returns: [section, course], string array length 2
public string[2] separateSectionCourse(string str) pure {
	int start = cast(int)str.indexOf('('),
			end = cast(int)str.indexOf(')');
	if (start < 0 || end <= start)
		return [null, str];
	return [str[start + 1 .. end].strip, str[0 .. start].strip];
}
