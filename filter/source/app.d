import std.stdio,
			 std.string;

import classfilter,
			 common;

/// CLI Options
struct Options{
	string[] courses;
	string[] coursesNeg;
	string[] sections;
	string[] sectionsNeg;
	string[] coursesSection;
	string[] coursesSectionNeg;
}

Options parse(string[] args){
	Options ret;
	enum Opt : ubyte{
		C = 1,
		S = 2,
		N = 4
	}
	ubyte opt = 0;
	foreach (arg; args[1 .. $]){
		if (arg.length && arg[0] == '-'){
			opt = 0;
			foreach (c; arg[1 .. $]){
				switch (c){
					case 'n': case 'N': opt |= Opt.N; break;
					case 'c': case 'C': opt |= Opt.C; break;
					case 's': case 'S': opt |= Opt.S; break;
					default:
						opt = 0;
						stderr.writefln!"Invalid filtering option found `%c`"(c);
						continue;
				}
			}
			continue;
		}
		switch (opt){
			case Opt.C: ret.courses ~= arg; break;
			case Opt.S: ret.sections ~= arg; break;
			case Opt.C | Opt.S: ret.coursesSection ~= arg; break;
			case Opt.N | Opt.C: ret.coursesNeg ~= arg; break;
			case Opt.N | Opt.S: ret.sectionsNeg ~= arg; break;
			case Opt.N | Opt.C | Opt.S: ret.coursesSectionNeg ~= arg; break;
			default:
				continue;
		}
	}
	return ret;
}

void main(string[] args){
	Options opts = args.parse();
	Filters filters;
	filters.sectionsRel = opts.sections;
	filters.coursesRel = opts.courses;
	if (!opts.courses.length &&
			!opts.coursesSection.length &&
			!opts.sections.length)
		filters.coursesRel = [".*"];

	filters.sectionsNeg = opts.sectionsNeg;
	filters.coursesNeg = opts.coursesNeg;

	filters.coursesSectionRel = separateSectionCourse(opts.coursesSection);
	filters.coursesSectionNeg = separateSectionCourse(opts.coursesSectionNeg);

	while (!stdin.eof){
		string line = readln.chomp("\n");
		if (line.length == 0) continue;
		writeln(line); // print name back

		while (!stdin.eof){
			line = readln.chomp("\n");
			if (line == "over")
				break;
			Class c;
			try{
				c = Class.deserialize(line);
			} catch (Exception){
				continue;
			}
			if (matches(filters, c))
				writeln(line);
		}
		writeln("over");
	}
}
