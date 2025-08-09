module app.stcomb;

import std.stdio,
			 std.range,
			 std.conv,
			 std.array,
			 std.regex,
			 std.algorithm;

import core.stdc.stdlib : exit;

import utils.ds;

import slowtable.combinator,
			 slowtable.common;

/// Default scoring system for Timetables. Use `S` to be `ClassMap`
/// Optimizes for:
/// - least number of days
/// - classes closest together
private struct Scorer{
	/// mean times for each day
	private float[7] mt = 0;
	/// session counts for each day
	private size_t[7] dc = 0;
	/// sum of deviations from mean
	private float dv = 0;
	/// score used to determine how good this combination is
	public float score = 0;

	this(const ClassMap cMap, const Scorer parent, size_t pick) {
		import std.math : abs;
		mt[] = parent.mt;
		dc[] = parent.dc;
		dv = parent.dv;
		// update mt and dc
		foreach (Class c; cMap.sessionsBySection[pick]){
			immutable size_t time =
				c.time.second + 60 * (c.time.minute + (60 * c.time.hour));
			mt[c.day] = ((mt[c.day] * dc[c.day]) + time) / (dc[c.day] + 1);
			dc[c.day] ++;
		}
		// update dv
		foreach (Class c; cMap.sessionsBySection[pick]){
			immutable size_t time =
				c.time.second + 60 * (c.time.minute + (60 * c.time.hour));
			dv += abs(mt[c.day] - time);
		}
		// count days, score = n(days) * dv
		immutable size_t days =
			(cast(size_t[])dc).map!(d => cast(ubyte)(d != 0)).sum;
		if (days)
			score = dv * days + (days << 16);
	}
}

void stcomb_main(string[] args){
	File input = stdin;//File("tt");
	ClassMap cMap = new ClassMap();
	if (args.canFind("--help") || args.canFind("-h")){
		stderr.writefln!"Usage:\n\t%s [options]\nOptions:"(args[0]);
		stderr.writefln!"\t-c/--count/--max\tSpecify maximum combinations";
		stderr.writefln!"\ta,b,c -k/--pick \tSpecify how many to pick from a,b,c";
		exit(0);
	}

	string[] selArgs = args[1 .. $];
	size_t topK = 50;
	if (args.length > 2 && (args[1] == "-k" || args[1] == "--top")){
		if (args.length < 3){
			stderr.writefln!"Missing value for -k / --top";
			exit(1);
		}
		try {
			topK = args[2].to!size_t;
		} catch (Exception e){
			stderr.writefln!"Expected +int for -k / --top: %s"(e.msg);
			exit(1);
		}
		selArgs = args[3 .. $];
	}
	string[][] sel;
	sel = selArgs.map!(s => s.split(",")).array;

	while (!input.eof){
		Timetable tt = Timetable.parse(input.byLineCopy);
		if (tt.classes is null)
			continue;
		cMap.reset();
		cMap.build(tt.classes);

		size_t count = 0;
		size_t[][] sids = getSids(cMap, sel);

		foreach (node; cMap.combinations!Scorer(cMap.clashMatrix, sids)){
			writefln!"%s combination %d"(tt.name, count);
			foreach (size_t sid; node.picks.keys){
				foreach (Class c; cMap.sessionsBySection[sid])
					c.serialize.writeln();
			}
			writefln!"over";
			if (++count >= topK)
				break;
		}
	}
}

size_t[][] getSids(ClassMap map, string[][] sel){
	Set!string picked;
	size_t[][] ret;
	foreach (selI; sel){
		size_t[] block;
		foreach (expr; selI){
			foreach (cid; map.courseSectionsRanges.length.iota.filter!(i =>
						matchFirst(
							map.namesBySid[map.courseSectionsRanges[i][0]][0], expr))){
				picked.put(map.namesBySid[map.courseSectionsRanges[cid][0]][0]);
				block ~= iota(
						map.courseSectionsRanges[cid][0],
						map.courseSectionsRanges[cid][0] +
						map.courseSectionsRanges[cid][1])
					.array;
			}
		}
		ret ~= block;
	}

	ret ~= map.courseSectionsRanges.length.iota
		.filter!(i => !picked.exists(
					map.namesBySid[map.courseSectionsRanges[i][0]][0]))
		.map!(i => iota(
					map.courseSectionsRanges[i][0],
					map.courseSectionsRanges[i][0] +
					map.courseSectionsRanges[i][1])
				.array)
		.array;
	return ret;
}
