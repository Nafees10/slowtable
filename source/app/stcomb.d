module app.stcomb;

import std.stdio,
			 std.conv,
			 std.algorithm;
import core.stdc.stdlib : exit;
import utils.ds, utils.misc;
import slowtable.combinator, slowtable.common;

alias TreeNode = slowtable.combinator.TreeNode;

void stcomb_main(string[] args){
	File input = stdin;//File("tt");
	ClassMap map = new ClassMap();
	if (args.canFind("--help") || args.canFind("-h")){
		writefln!"Usage:\n\t%s [maxCombinations]"(args[0]);
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

	while (!input.eof){
		Timetable tt = Timetable.parse(input.byLineCopy);
		if (tt.classes is null)
			continue;
		map.reset();
		map.build(tt.classes);

		size_t count = 0;
		foreach (TreeNode node; Combinator(new TreeNode(null, map))){
			writefln!"%s combination %d"(tt.name, count);
			foreach (size_t sid; node.picks.keys){
				foreach (Class c; node.map.sessions[sid])
					c.serialize.writeln();
			}
			writefln!"over";
			if (++count >= maxC)
				break;
		}
	}
}
