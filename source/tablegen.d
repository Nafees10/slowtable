module tablegen;

import std.algorithm;
import std.string;
import std.datetime;
import std.conv;

import fasttable;

/// Generates a HTML table for classes
string generateTable(Class[] classesUnsorted){
	TimeOfDay[2] timeExtremes = classesTimeMinMax(classesUnsorted);
	TimeOfDay timeMin = timeExtremes[0], timeMax = timeExtremes[1];
	string ret =
`<style>
table{border-collapse:collapse;}
table td, table th{border:1px solid black;}
table tr:first-child th{border-top:0;}
table tr:last-child td{border-bottom:0;}
table tr td:first-child,table tr th:first-child{border-left:0;}
table tr td:last-child,table tr th:last-child{border-right:0;}
</style>
<table style='width:100%;border: solid 1px'><tr><th>Day</th><th>Venue</th>`;

	Class[][string][DayOfWeek] classes; // classes by Day, and Venue
	// sort out the mess
	foreach (c; classesUnsorted){
		classes[c.day][c.venue] ~= c;
	}
	foreach (ref classesOfDay; classes){
		foreach (ref classesByVenue; classesOfDay)
			classesSort(classesByVenue);
	}

	// generate timing legend
	foreach (hour; timeMin.hour .. timeMax.hour + 1)
		ret ~= "<th colspan=6>" ~ hour.to!string ~ "</th>";
	ret ~= "</tr><tr><th></th><th></th>";
	foreach (hour; timeMin.hour .. timeMax.hour + 1){
		foreach (minute; 0 .. 6){
			minute *= 10;
			ret ~= "<th>" ~ minute.to!string ~ "</th>";
		}
	}

	// populate the whole table
	foreach (day; DayOfWeek.mon .. DayOfWeek.sat){
		ret ~= "<tr><th rowspan=" ~ classes[day].length.to!string ~ ">" ~
			day.to!string ~ "</th>";

		foreach (venue, vClasses; classes[day]){
			ret ~= "<th>" ~ venue ~ "</th>";
			uint x = timeMin.hour * 60; // current position, in minutes
			foreach (c; vClasses){
				const uint minutes = c.time.hour * 60 + c.time.minute;
				if (minutes > x){
					foreach (i; 0 .. (minutes - x) / 10)
						ret ~= "<td></td>";
				}
				ret ~= "<td colspan=" ~ (c.duration.total!"minutes" / 10).to!string ~
					">" ~ c.name ~ " - " ~ c.section ~ "</td>";
				x = minutes + cast(uint)c.duration.total!"minutes";
			}
			for (uint i = x; i < (timeMax.hour + 1) * 60; i += 10)
				ret ~= "<td></td>";
			ret ~= "</tr><tr>";
		}
		ret = ret.chomp("<tr>");

		ret ~= "</tr>";
	}

	ret ~= "</table>";
	return ret;
}
