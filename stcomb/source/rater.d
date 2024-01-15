module rater;

import std.datetime;

import common;

/// Rates consistency of a timetable.
/// Params: `classes` is sorted classes of timetable, by days
/// Returns: rating (lower is better), range is 0 to 1000
uint rateConsistency(Class[][DayOfWeek] classes){
	if (classes.length == 0)
		return 0; // best timetable lol
	TimeOfDay prevStart = classes[classes.keys[0]][0].time,
						prevEnd = classes[classes.keys[0]][$ - 1].time +
							classes[classes.keys[0]][$ - 1].duration;
	classes.remove(classes.keys[0]);
	size_t diff = 0;
	foreach (day, sessions; classes){
		TimeOfDay start = sessions[0].time,
							end = sessions[$ - 1].time + sessions[$ - 1].duration;
		diff += ((start > prevStart ? start - prevStart : prevStart - start)
				+ (end > prevEnd ? end - prevEnd : prevEnd - end)).total!"minutes";
		prevStart = start;
		prevEnd = end;
	}
	return cast(uint)(diff * 1000 / (7 * 24 * 60));
}

/// Rates how many days timetable spans
/// Params: `classes` is classes of timetable, in any order
/// Returns: rating (lower is better), range is 0 to 1000
uint rateDays(Class[] classes){
	ubyte flags;
	ubyte count;
	foreach (session; classes){
		count += !(flags & (1 << session.day));
		flags |= 1 << session.day;
	}
	return count * 1000 / 7;
}

/// Rates how many gaps there are in timetable
/// Params: `classes` is sorted classes of timetable, by days
/// Returns: rating (lower is better), range is 0 to 1000
uint rateGaps(Class[][DayOfWeek] classes){
	size_t gaps;
	foreach (day, sessions; classes){
		if (sessions.length == 0)
			continue;
		foreach (i, curr; sessions[1 .. $]){
			Class prev = sessions[i];
			gaps += (curr.time - (prev.time + prev.duration)).total!"minutes";
		}
	}
	return cast(uint)(gaps * 1000 / (7 * 24 * 60));
}

/// Rates a timetable based on consistency, days, and gaps
/// Params:
/// * `classes` is the timetable. it will be mutated (sorted)
/// * weights for rating methods
/// Returns: rating, 0 to 1000. Lower is better
uint rate(Class[] classes, uint consistency = 1, uint days = 1, uint gaps = 1){
	int ret;
	classesSortByTime(classes);
	Class[][DayOfWeek] byDays;

	if (consistency && gaps){
		foreach (session; classes){
			if (session.day !in byDays)
				byDays[session.day] = [session];
			else
				byDays[session.day] ~= session;
		}

		if (consistency)
			ret += consistency * rateConsistency(byDays);
		if (gaps)
			ret += gaps * rateGaps(byDays);
	}
	ret += days * rateDays(classes);
	return ret / (consistency + days + gaps);
}
