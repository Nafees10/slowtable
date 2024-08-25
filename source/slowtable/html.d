module slowtable.html;

import std.algorithm,
			 std.string,
			 std.datetime,
			 std.conv;

import slowtable.common;
import utils.misc : readHexadecimal;

private struct RGB{
	ubyte r, g, b;

	this(ubyte r, ubyte g, ubyte b) pure {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	this(uint rgb) pure {
		this.r = (rgb >> 16) & 255;
		this.g = (rgb >> 8) & 255;
		this.b = rgb & 255;
	}

	/// Returns: luminance
	@property float luminance() const pure {
		return 0.2126*r + 0.7152*g + 0.0722*b;
	}

	/// Returns: suitable foreground color for this background color
	@property RGB foreground() const pure {
		return luminance < 140 ? RGB(255, 255, 255) : RGB(0, 0, 0);
	}

	string toCSS() const pure {
		RGB fore = foreground;
		return format!"background:rgb(%d,%d,%d);color:rgb(%d,%d,%d);"(
				r, g, b, fore.r, fore.g, fore.b);
	}
}

private enum uint[] COLORS = [
	0xa2b9bc,
	0x6b5b95,
	0xb2ad7f,
	0xfeb236,
	0xd64161,
	0x86af49,
	0xb5e7a0,
	0xeca1a6,
	0xbdcebe,
	0xada397,
	0xe3eaa7,
	0x405d27,
	0x3e4444,
	0xb9936c,
	0x92a8d1,
	0x034f84,
	0x50394c,
	0x80ced6,
	0x618685,
];

/// Generates css color styles for sections
/// Returns: css color styles for section string
private size_t[string] colorize(uint[] Colors = COLORS)(Class[] classes){
	size_t[string] ret;
	foreach (c; classes){
		if (c.section in ret)
			continue;
		ret[c.section] = ret.length % Colors.length;
	}
	return ret;
}

/// style tag for table
template HTML_STYLE(uint[] Colors = COLORS){
	enum HTML_STYLE = generateStyleStr();
	string generateStyleStr(){
		string ret =
`<style>
table{border-collapse:collapse;text-align:center;width:100%;border:solid 1px;}
table td, table th{border:1px solid black;}
table tr:first-child th{border-top:0;}
table tr:last-child td{border-bottom:0;}
table tr td:first-child,table tr th:first-child{border-left:0;}
table tr td:last-child,table tr th:last-child{border-right:0;}
tr:nth-child(even){background-color:#f2f2f2;}`.replace("\n","");
		foreach (i, color; Colors)
			ret ~= format!".c%d {%s} "(i, RGB(Colors[i]).toCSS);
		return ret ~ "</style>";
	}
}

/// Generates a HTML table for classes
string generateTable(Class[] classesUnsorted, uint interval = 10){
	TimeOfDay[2] timeExtremes = classesUnsorted.timeMinMax;
	TimeOfDay timeMin = timeExtremes[0], timeMax = timeExtremes[1];
	string ret;

	Class[][string][DayOfWeek] classes = classesUnsorted.sortByVenueDay;
	foreach (ref classesOfDay; classes){
		foreach (ref classesByVenue; classesOfDay)
			classesByVenue.sortByTime;
	}

	size_t[string] colors = colorize!()(classesUnsorted);

	// populate the whole table
	ret ~= "<table>";
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
				// TODO: what does table-style: fixed even do????
				//ret ~= "<th style='table-style:fixed;'>" ~ minute.to!string ~ "</th>";
				ret ~= "<th>" ~ minute.to!string ~ "</th>";
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
				ret ~= "<td class=c" ~ colors[c.section].to!string ~ " colspan=" ~
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
