module tablegen;

import std.algorithm;
import std.string;
import std.datetime;
import std.conv;

import slowtable;
import colors;

/// Generates css color styles for sections
/// Returns: css color styles for section string
private string[string] colorize(Class[] classes){
	string[string] ret;
	foreach (c; classes){
		if (c.section in ret)
			continue;
		ret[c.section] = COLORS[ret.length % $].toCSS;
	}
	return ret;
}

/// style tag for table
enum HTML_STYLE =
`<style>
table{border-collapse:collapse;text-align:center;width:100%;}
table td, table th{border:1px solid black;}
table tr:first-child th{border-top:0;}
table tr:last-child td{border-bottom:0;}
table tr td:first-child,table tr th:first-child{border-left:0;}
table tr td:last-child,table tr th:last-child{border-right:0;}
tr:nth-child(even){background-color:#f2f2f2;}
</style>`;

/// Generates a HTML table for classes
string generateTable(Class[] classesUnsorted, uint interval){
	TimeOfDay[2] timeExtremes = classesTimeMinMax(classesUnsorted);
	TimeOfDay timeMin = timeExtremes[0], timeMax = timeExtremes[1];
	string ret = HTML_STYLE;

	Class[][string][DayOfWeek] classes = classesSortByDayVenue(classesUnsorted);
	foreach (ref classesOfDay; classes){
		foreach (ref classesByVenue; classesOfDay)
			classesSortByTime(classesByVenue);
	}

	string[string] colors = colorize(classesUnsorted);

	// populate the whole table
	ret ~= "<table style='width:100%;border:solid 1px;'>";
	const uint minutesMax = (timeMax.hour + 1) * 60 + timeMax.minute;
	foreach (dayI; DayOfWeek.mon .. DayOfWeek.sat + 1){
		const DayOfWeek day = cast(DayOfWeek)dayI;
		if (day !in classes)
			continue;
		ret ~= "<tr><th rowspan=2>Day</th><th rowspan=2>Venue</th>";
		// generate timing legend
		foreach (hour; timeMin.hour .. timeMax.hour + 1)
			ret ~= "<th colspan=6>" ~ hour.to12hr ~ "</th>";
		ret ~= "</tr><tr>";
		foreach (hour; timeMin.hour .. timeMax.hour + 1){
			foreach (minute; 0 .. 60 / interval){
				minute *= interval;
				ret ~= "<th style='table-style:fixed;'>" ~ minute.to!string ~ "</th>";
			}
		}
		ret ~= "<tr><th rowspan=" ~ classes[day].length.to!string ~ ">" ~
			day.to!string ~ "</th>";

		foreach (venue, vClasses; classes[day]){
			ret ~= "<th>" ~ venue ~ "</th>";
			uint x = timeMin.hour * 60; // current position, in minutes
			foreach (c; vClasses){
				const uint minutes = c.time.hour * 60 + c.time.minute;
				if (minutes > x){
					ret ~= "<td colspan=" ~ ((minutes - x) / interval).to!string ~
						"></td>";
				}
				ret ~= "<td style=\"" ~ colors[c.section] ~ "\" colspan=" ~
					(c.duration.total!"minutes" / interval).to!string ~ ">" ~
					c.name ~ " - " ~ c.section ~ "</td>";
				x = minutes + cast(uint)c.duration.total!"minutes";
			}
			if (minutesMax > x){
				ret ~= "<td colspan=" ~ ((minutesMax - x) / interval).to!string ~
					"></td>";
			}
			ret ~= "</tr><tr>";
		}
		ret = ret.chomp("<tr>");

		ret ~= "</tr><tr><th></th><th></th></tr>";
	}

	ret ~= "</table>";
	return ret;
}

private string to12hr(uint hour) pure {
	if (hour == 12)
		return "12 pm";
	return (hour % 12).to!string ~ (hour < 12 ? " am" : " pm");
}
