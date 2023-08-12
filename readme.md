# slowtable
Set of tools to manage timetables, including a parser to read timetables for
FAST NUCES Lahore.

## Features

1. Simple UNIX philosophy following tools
1. JSON for communication
1. Regex based filtering
1. Advanced filtering tool
1. Colored output (per section)

---

## Prerequisites

1. Libreoffice - convert `xlsx` to `ods`, since `slowparser` only accepts `ods`
1. A D compiler, and `dub` - both can be downloaded from
[here](https://dlang.org/download.html#dmd)
1. `git` - to clone repo, or you can download the code from github

## Building

Run the following to clone and build:

```bash
git clone https://github.com/Nafees10/slowtable
cd slowtable
dub build :slowparser -b=release
dub build :slowfilter -b=release
dub build :tablemaker -b=release
```

This will create executables in the `bin` folder.

---

## Tools

Run any of these tools with the `--help` flag to show help.

## `slowparser`

Reads a FAST NUCES Lahore's timetable file (timetable must be first sheet), and
outputs an array of array of JSON objects describing each class:

```json
[
	[
		...,
		{
			"day": "mon",
			"duration": 80,
			"name": "data structures",
			"section": "BDS-3B",
			"time": "08:30:00",
			"venue": "Seminar Hall"
		},
		...
	]
]
```

The outermost array is an array of timetables, where each timetable is an array
of objects.

## `slowfilter`

Reads array of JSON objects for classes, and runs them through a set of filters,
outputting objects in same structure, which pass the filter.

### Filtering

The filter ignores any non-alphanumeric characters in courses names, to make
filtering easier, and it also lowercases all course names. But section names are
kept as it is.
For example, the course `Software Design & Architecture` will be read as
`software design architecture`.

All filters are regular expressions.

When no `-s`, `-c`, or `-cs` filters are provided, the `-c` filter is defaulted
to be `.*` so it includes all courses of all sections. So any negating filters
can be used without the `-s`, `-c`, or `-cs` filters.

#### `-s section`
Use the `-s` flag to filter for sections.  
For example, to only include courses for all sections of `BSE-4`, run the
following:
```bash
./slowfilter input.ods -s BSE-4
```

To only include courses for `BSE-4A` and `BCS-4A`, run the following:
```bash
slowfilter -s BSE-4A BCS-4A
```

#### `-ns section`
Use the `-ns` flag to filter _out_ a section.
For example, to exclude all Masters courses, while keeping all BS courses:
```
slowfilter -ns 'M\S\S-'
```
this uses the regex filter `M\S\S` to match any section that begins with M
followed by 2 alphabets followed by a `-`.

#### `-c course`
Use the `-c` flag to filter for courses, i.e: include _all_ sections of a
specific course.
For example, to include all sections of Object Oriented Programming, run the
following:
```bash
slowfilter -c 'Object Oriented Programming'
```

#### `-nc course`
Use the `-nc` flag to filter _out_ a course.
For example, to include all courses of BSE-4, except for `Data Structures`:
```bash
slowfilter -s BSE-4 -nc 'Data Structures'
```

#### `-cs course (section)`
Use the `-cs` flag to include a specific course of a specific section.
For example, to include all `BSE-4A` courses, along with
`Database Systems (BSE-4B)`:
```bash
slowfilter -s BSE-4A -cs 'Database (BSE-4B)'
```

#### `-ncs course (section)`
Use the `-cs` flag to exclude a specific course of a specific section.
For example, to include all `BSE-4` courses, except for
`Software Design .. (BSE-4B)`:
```bash
slowfilter -s BSE-4 -ncs 'Software Design (BSE-4B)'
```

## `tablemaker`

Takes input array of timetables, and outputs html rendering for them.

---

## Usage
First to convert an xlsx timetable file to ods, run the following:
```bash
libreoffice --headless --convert-to ods path/to/timetable.xlsx
```

Then use `slowparser` to extract JSON information from it:
```bash
slowparser timetable.ods > timetable.json
```

From there onwards, slowtable tools can be used with the JSON data:
```bash
cat timetable.json | slowfilter -s BSE-5 > bse5-timetable.json
cat bse5-timetable.json | tablemaker > bse5-timetable.html
```

The generated HTML file can be opened by a web browser.

---

## Acknowledgments
This program uses TransientResponse's [`dlang-ods`](https://github.com/TransientResponse/dlang-ods) library.
