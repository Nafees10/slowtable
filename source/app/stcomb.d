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
		foreach (Node!ScoreDev node; Combinator!ScoreDev(cMap, sids)){
			writefln!"%s combination %d"(tt.name, count);
			foreach (size_t sid; node.picks.keys){
				foreach (Class c; cMap.sessionsBySid[sid])
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
			foreach (cid; map.cidsRange.length.iota.filter!(i =>
						matchFirst(map.namesBySid[map.cidsRange[i][0]][0], expr))){
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
