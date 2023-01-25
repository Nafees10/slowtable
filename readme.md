# fastable
Tool to clean up timetable sent by FAST NUCES.

---

## Features

1. Regex based filtering
1. Filtering based on course(s) and/or section(s)
1. Negating courses, sections, and course-section combo
1. Colored output (per section)

---

## Prerequisites

1. Libreoffice (headless) - to convert xlsx to ods
1. A D compiler (`dmd`)
1. `dub` build tool
1. `git` - to clone repo

## Building

Run the following to clone and build:
```bash
git clone https://github.com/Nafees10/fastable
cd fastable
dub build -b=release
```
This will create a binary named `fastable`.

---

## Usage
First to convert an xlsx timetable file to ods, run the following:
```bash
libreoffice --headless --convert-to ods path/to/timetable.xlsx
```

From there onwards, fastable can be run:
```bash
./fastable path/to/converted/timetable.ods [commands] > output.html
```

Running the above will generate a HTML file containing exact same contents as
original timetable. Use filters (read below) to filter out irrelevant courses
and sections.

## Filtering

All filters are regular expressions.

When no `-s` or `-c` filters are provided, all courses/sections are included,
and any negated filters are used.

### `-s` section
Use the `-s` flag to filter for sections.  
For example, to only include courses for all sections of `BSE-4`, run the
following:
```bash
./fastable input.ods -s BSE-4 > table.html
```

To only include courses for `BSE-4A` and `BCS-4A`, run the following:
```bash
./fastable input.ods -s BSE-4A BCS-4A > table.html
```

### `-ns` section
Use the `-ns` flag to filter _out_ a section.
For example, to exclude all Masters courses, while keeping all BS courses:
```
./fastable input.ods -ns 'M\S\S-' > table.html
```
this uses the regex filter `M\S\S` to match any section that begins with M followed by 2 alphabets followed by a `-`.

### `-c` course
Use the `-c` flag to filter for courses, i.e: include _all_ sections of a
specific course.
For example, to include all sections of Object Oriented Programming, run the
following:
```bash
./fastable input.ods -c 'Object Oriented Programming' > table.html
```

### `-nc` course
Use the `-nc` flag to filter _out_ a course.
For example, to include all courses of BSE-4, except for `Data Structures`:
```bash
./fastable input.ods -s BSE-4 -nc 'Data Structures' > table.html
```

### `-cs` course (section)
Use the `-cs` flag to include a specific course of a specific section.
For example, to include all `BSE-4A` courses, along with
`Database Systems (BSE-4B)`:
```bash
./fastable input.ods -s BSE-4A -cs 'Database (BSE-4B)' > table.html
```

### `-ncs` course (section)
Use the `-cs` flag to exclude a specific course of a specific section.
For example, to include all `BSE-4` courses, except for
`Software Design .. (BSE-4B)`:
```bash
./fastable input.ods -s BSE-4 -ncs 'Software Design (BSE-4B)' > table.html
```

---

## Acknowledgments
This program uses a modified version of TransientResponse's [`dlang-ods`](https://github.com/TransientResponse/dlang-ods) library.
