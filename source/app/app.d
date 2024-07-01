module app.app;

import std.stdio;

import app.stcomb,
			 app.stfilter,
			 app.stdelab,
			 app.sthtml,
			 app.stparse;

void main(string[] args){
	switch (args[0]){
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
			stderr.writefln!"Invalid argv[0] `%s` for multi-call binary"(args[0]);
	}
}
