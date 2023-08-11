module common;

import std.json,
			 std.datetime,
			 std.format,
			 std.algorithm,
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
	assert (d.time == c.time, d.time.toISOExtString ~ " != " ~ c.time.toISOExtString);
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
