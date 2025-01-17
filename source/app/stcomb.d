module app.stcomb;

import std.stdio,
			 std.range,
			 std.conv,
			 std.array,
			 std.regex,
			 std.algorithm;
import core.stdc.stdlib : exit;
import utils.ds, utils.misc;
import slowtable.combinator, slowtable.common;

alias Node = slowtable.combinator.Node;

private struct Opts{
	string[][] sel;
	size_t maxComb = 200;

	public static Opts parse(string[] args){
		Opts ret;
		string prev;
		for (size_t i = 0; i < args.length; i ++){
			switch (args[i]){
				case "-c", "--count", "--max":
					if (i + 1 >= args.length) {
						stderr.writefln!"Missing value for -c / --count / --max";
						exit(1);
					}
					try {
						ret.maxComb = args[i + 1].to!size_t;
					} catch (Exception e) {
						stderr.writefln!"Invalid value for max -c / --count / --max.";
						exit(1);
					}
					i ++;
					break;
				case "-k", "--pick":
					if (!prev) {
						stderr.writefln!"Missing selection for -k / -pick";
						exit(1);
					}
					if (i + 1 >= args.length){
						stderr.writefln!"Missing value for -k / --pick";
						exit(1);
					}
					size_t count;
					try {
						count = args[i + 1].to!size_t;
					} catch (Exception e) {
						stderr.writefln!"Invalid value for -k / -- pick";
						exit(1);
					}
					string[] splits = prev.split(",");
					if (splits.length){
						foreach (j; 0 .. count)
							ret.sel ~= splits;
					}
					prev = null;
					i ++;
					break;
				default:
					if (prev)
						ret.sel ~= prev.split(",");
					prev = args[i];
			}
		}
		if (prev)
			ret.sel ~= prev.split(",");
		return ret;
	}
}

void stcomb_main(string[] args){
	Opts opts = Opts.parse(args[1 .. $]);
	File input = stdin;//File("tt");
	ClassMap map = new ClassMap();
	if (args.canFind("--help") || args.canFind("-h")){
		stderr.writefln!"Usage:\n\t%s [options]\nOptions:"(args[0]);
		stderr.writefln!"\t-c/--count/--max\tSpecify maximum combinations";
		stderr.writefln!"\ta,b,c -k/--pick \tSpecify how many to pick from a,b,c";
		exit(0);
	}

	while (!input.eof){
		Timetable tt = Timetable.parse(input.byLineCopy);
		if (tt.classes is null)
			continue;
		map.reset();
		map.build(tt.classes);

		size_t count = 0;
		size_t[][] sids = getSids(map, opts.sel);
		foreach (Node!ScoreDev node; Combinator!ScoreDev(map, sids)){
			writefln!"%s combination %d"(tt.name, count);
			foreach (size_t sid; node.picks.keys){
				foreach (Class c; map.sessionsBySid[sid])
					c.serialize.writeln();
			}
			writefln!"over";
			if (++count >= opts.maxComb)
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
			foreach (cid; map.cidsRange.length.iota
					.filter!(i => matchFirst(map.namesBySid[map.cidsRange[i][0]][0], expr)
						/*&& !picked.exists(map.names[map.cidsRange[i][0]][0])*/)){
				picked.put(map.namesBySid[map.cidsRange[cid][0]][0]);
				block ~= iota(map.cidsRange[cid][0],
						map.cidsRange[cid][0] + map.cidsRange[cid][1]).array;
			}
		}
		ret ~= block;
	}

	ret ~= map.cidsRange.length.iota
		.filter!(i => !picked.exists(map.namesBySid[map.cidsRange[i][0]][0]))
		.map!(i => iota(map.cidsRange[i][0],
					map.cidsRange[i][0] + map.cidsRange[i][1]).array)
		.array;
	return ret;
}
