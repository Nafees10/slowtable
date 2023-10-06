module common;

import std.json,
			 std.datetime,
			 std.format,
			 std.algorithm,
			 std.string,
			 std.uni,
			 std.conv : to;

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

	/// Serializes into a tab separated line
	/// `name section venue day time duration(minutes)`
	string serialize() const {
		return format!"\t%s\t%s\t%s\t%s\t%s\t%d"(
				name, section, venue, day, time.toISOString, duration.total!"minutes");
	}

	/// Deserialize from a tab separated line
	/// Throws: Exception when invalid format
	/// Returns: deserialized Class
	static Class deserialize(string line){
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

	/// Returns: whether this equals another Class
	/*bool opEquals(ref Class rhs) const pure {
		return
			this.name == rhs.name &&
			this.section == rhs.section &&
			this.venue == rhs.venue &&
			this.day == rhs.day &&
			this.time == rhs.time &&
			this.duration == rhs.duration;
	}*/

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

	JSONValue jsonOf() const {
		JSONValue ret;
		ret["day"] = JSONValue(day.to!string);
		ret["time"] = JSONValue(time.toISOExtString);
		ret["duration"] = JSONValue(duration.total!"minutes");
		ret["name"] = JSONValue(name);
		ret["section"] = JSONValue(section);
		ret["venue"] = JSONValue(venue);
		return ret;
	}

	this (DayOfWeek day, TimeOfDay time, Duration duration, string name,
			string section, string venue){
		this.day = day;
		this.time = time;
		this.duration = duration;
		this.name = name;
		this.section = section;
		this.venue = venue;
	}

	this(JSONValue json){
		day = json["day"].get!string.to!DayOfWeek;
		time = TimeOfDay.fromISOExtString(json["time"].get!string);
		duration = dur!"minutes"(json["duration"].get!int);
		name = json["name"].get!string;
		section = json["section"].get!string;
		venue = json["venue"].get!string;
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

/// Sorts classes by time
void classesSortByTime(ref Class[] classes){
	classes.sort!"a.timeEncode < b.timeEncode";
}

/// Sorts classes by venue and day
Class[][string][DayOfWeek] classesSortByDayVenue(Class[] classes){
	Class[][string][DayOfWeek] ret;
	foreach (c; classes)
		ret[c.day][c.venue] ~= c;
	return ret;
}

/// Finds earliest starting time, and latest ending time
/// Returns: [starting time, ending time]
TimeOfDay[2] classesTimeMinMax(Class[] classes){
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
bool overlaps(Class a, Class b) pure {
	return a.time < b.time + b.duration && b.time < a.time + a.duration;
}

/// Cleans up a name/section string
/// Returns: cleaned up string
string clean(string str) pure {
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
	assert("  \tbla \t \n- bla-bla   \t  \n ".clean == "bla bla bla");
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
