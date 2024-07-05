module app.app;

import std.stdio,
			 std.path;

import app.stcomb,
			 app.stfilter,
			 app.stdelab,
			 app.sthtml,
			 app.stparse;

void main(string[] args){
	string name = args[0].baseName;
	switch (name){
		case "stparse":
			stparse_main(args);
			break;
		case "stfilter":
			stfilter_main(args);
			break;
		case "stdelab":
			stdelab_main(args);
			break;
		case "stcomb":
			stcomb_main(args);
			break;
		case "sthtml":
			sthtml_main(args);
			break;
		default:
			stderr.writefln!"Invalid argv[0] `%s` for multi-call binary"(name);
	}
}
