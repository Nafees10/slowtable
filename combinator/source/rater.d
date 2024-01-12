module rater;

import std.datetime;

import common;

/// Rates consistency of a timetable.
/// Params: `classes` is sorted classes of timetable, by days
/// Returns: rating (lower is better), range is 0 to 1000
int rateConsistency(Class[][DayOfWeek] classes){
	if (classes.length == 0)
		return 0; // best timetable lol
	TimeOfDay prevStart = classes[classes.keys[0]][0].time,
						prevEnd = classes[classes.keys[0]][$ - 1].time +
							classes[classes.keys[0]][$ - 1].duration;
	classes.remove(classes.keys[0]);
	long diff = 0;
	foreach (day, sessions; classes){
		TimeOfDay start = sessions[0].time,
							end = sessions[$ - 1].time + sessions[$ - 1].duration;
		diff += ((start - prevStart) + (end - prevEnd)).total!"minutes";
		prevStart = start;
		prevEnd = end;
	}
	return cast(int)(diff * 1000 / (7 * 24 * 60));
}

/// Rates how many days timetable spans
/// Params: `classes` is classes of timetable, in any order
/// Returns: rating (lower is better), range is 0 to 1000
int rateDays(Class[] classes){
	ubyte flags;
	int count;
	foreach (session; classes){
		count += !(flags & (1 << session.day));
		flags |= 1 << session.day;
	}
	return count;
}

/// Rates how many gaps there are in timetable
/// Params: `classes` is sorted classes of timetable, by days
/// Returns: rating (lower is better), range is 0 to 1000
int rateGaps(Class[][DayOfWeek] classes){
	long gaps;
	foreach (day, sessions; classes){
		foreach (session; sessions){
// TODO continue from here
		}
	}
	return cast(int)(gaps * 1000 / (7 * 24 * 60));
}
