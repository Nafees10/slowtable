# slowtable
Set of tools to manage timetables, including a parser to read timetables for
FAST NUCES Lahore.

## Features

1. Simple UNIX philosophy following tools
1. Simple serialized format, human readable
1. Regex based filtering
1. Advanced filtering tool
1. Colored output (per section)

---

## Prerequisites

1. Libreoffice - convert `xlsx` to `ods`, since `stparse` only accepts `ods`
1. A D compiler (`ldc`), and `dub` - both can be downloaded from
[here](https://dlang.org/download.html#dmd)
1. `git` - to clone repo, or you can download the code from github

## Building

Run the following to clone and build:

```bash
git clone https://github.com/Nafees10/slowtable
cd slowtable
./build.sh
./link.sh
```

This will create executables in the `bin` folder.

The `./link.sh` script will create symlinks in `~/.local/bin/`, making the
binaries runnable without needing to `cd` into `slowtable/bin/`, if you have
`~/.local/bin/` in your `$PATH`.

---

## Tools

Run any of these tools with the `--help` flag to show help.

## `stparse`

Reads a FAST NUCES Lahore's timetable file (timetable must be first sheet), and
outputs a serialized list of Classes, tab separated values, with a tab at start:

```
TimetableName
	courseName	courseSection	venue	day	timeISOString	durationMinutes
	...
over
```

for example:

```
Fall2023.ods[0]
	...
	operations research	BSE-5C	E&M-2	mon	143000	80
	operations research	BSE-5B	CE-1	mon	113000	80
	operations research	BSE-5A	CS-1	mon	100000	80
	operations research	BSE-5C	E&M-2	wed	143000	80
	operations research	BSE-5A	CS-1	wed	100000	80
	operations research	BSE-5B	CS-5	fri	113000	80
	...
over
```

## `stdelab`

Renames labs to courses. Useful when output of `stparse` is going to `stcomb`,
pass it through `stdelab` so stcomb sees labs as same as course, generating
same sections for both.

Example:

```bash
stparse tt.ods 0 10 | stdelab > tt
```

## `stfilter`

Reads list of classes, and runs them through a set of filters, outputting
objects in same structure, which pass the filter.

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
stparse input.ods | stfilter -s BSE-4
```

To only include courses for `BSE-4A` and `BCS-4A`, run the following:

```bash
stfilter -s BSE-4A BCS-4A
```

#### `-ns section`

Use the `-ns` flag to filter _out_ a section.
For example, to exclude all Masters courses, while keeping all BS courses:

```
stfilter -ns 'M\S\S-'
```

this uses the regex filter `M\S\S` to match any section that begins with M
followed by 2 alphabets followed by a `-`.

#### `-c course`

Use the `-c` flag to filter for courses, i.e: include _all_ sections of a
specific course.
For example, to include all sections of Object Oriented Programming, run the
following:

```bash
stfilter -c 'Object Oriented Programming'
```

#### `-nc course`

Use the `-nc` flag to filter _out_ a course.
For example, to include all courses of BSE-4, except for `Data Structures`:
```bash
stfilter -s BSE-4 -nc 'Data Structures'
```

#### `-cs course (section)`

Use the `-cs` flag to include a specific course of a specific section.
For example, to include all `BSE-4A` courses, along with
`Database Systems (BSE-4B)`:
```bash
stfilter -s BSE-4A -cs 'Database (BSE-4B)'
```

#### `-ncs course (section)`

Use the `-cs` flag to exclude a specific course of a specific section.
For example, to include all `BSE-4` courses, except for
`Software Design .. (BSE-4B)`:
```bash
stfilter -s BSE-4 -ncs 'Software Design (BSE-4B)'
```

## `sthtml`

Takes input (stdin) timetable(s), and outputs HTML for each.

Example:

```bash
cat BSE-5 | sthtml > BSE-5.html
```

## `stcomb`

Takes input timetables, and outputs all possible non-clashing combinations,
sorted from best to worst.

It takes one optional argument: maximum number of combinations to generate.

Example:

```bash
cat BSE-5 | stcomb | sthtml > BSE-5-all.html
```

---

## Usage

First to convert an xlsx timetable file to ods, run the following:

```bash
libreoffice --headless --convert-to ods path/to/timetable.xlsx
```

Then use `stparse` to extract timetable information from it:

```bash
stparse timetable.ods > timetable
```

From there onwards, slowtable tools can be used with the timetable data:

```bash
cat timetable | stfilter -s BSE-5 > bse5-timetable
cat bse5-timetable | sthtml > bse5-timetable.html
cat bse5-timetable | stcomb | sthtml > bse5-timetables-all.html
```

The generated HTML files can be opened by a web browser.

---

## Acknowledgments
This program uses TransientResponse's
[`dlang-ods`](https://github.com/TransientResponse/dlang-ods) library.
