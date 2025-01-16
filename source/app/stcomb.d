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
	ClassMap map = new ClassMap();
	if (args.canFind("--help") || args.canFind("-h")){
		writefln!"Usage:\n\t%s [maxCombinations] [electiveA,electiveB] ..."(
				args[0]);
		exit(0);
	}

	size_t maxC = 200;
	if (args.length > 1){
		try{
			maxC = args[1].to!size_t;
		} catch (Exception e){
			stderr.writefln!"Expected integer for maxCombinations, found `%s`"(maxC);
			exit(1);
		}
	}

	string[][] sel;
	if (args.length > 2)
		sel = args[2 .. $].map!(s => s.split(",")).array;

	while (!input.eof){
		Timetable tt = Timetable.parse(input.byLineCopy);
		if (tt.classes is null)
			continue;
		map.reset();
		map.build(tt.classes);

		size_t count = 0;
		size_t[][] sids = getSids(map, sel);
		stderr.writefln!"sids: %s"(sids);
		foreach (Node!ScoreDev node; Combinator!ScoreDev(map, sids)){
			writefln!"%s combination %d"(tt.name, count);
			foreach (size_t sid; node.picks.keys){
				foreach (Class c; map.sessionsBySid[sid])
					c.serialize.writeln();
			}
			writefln!"over";
			if (++count >= maxC)
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
