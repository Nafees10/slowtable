# slowtable
Tool to clean up timetable sent by FAST NUCES.

---

## Features

1. Regex based filtering
1. Filtering based on course(s) and/or section(s)
1. Negating courses, sections, and course-section combo
1. Colored output (per section)

---

## Prerequisites

1. Libreoffice (headless) or google sheets - to convert xlsx to ods
1. A D compiler, and `dub` - both can be downloaded from
[here](https://dlang.org/download.html#dmd)
1. `git` - to clone repo, or you can download the code from github

## Building

Run the following to clone and build:
```bash
git clone https://github.com/Nafees10/slowtable
cd slowtable
dub build -b=release
```
This will create a binary named `slowtable`.

---

## Usage
First to convert an xlsx timetable file to ods, run the following:
```bash
libreoffice --headless --convert-to ods path/to/timetable.xlsx
```
Or alternatively, you can upload the xlsx file to google sheets, and Download
in OpenDocument format (ods).

From there onwards, slowtable can be run:
```bash
./slowtable path/to/converted/timetable.ods [commands] > output.html
```

Running the above will generate a HTML file containing exact same contents as
original timetable. Use filters (read below) to filter out irrelevant courses
and sections.

The generated HTML file can be opened by a web browser.

## Filtering

The parser ignores any non-alphanumeric characters in courses names, to make
filtering easier, and it also lowercases all course names. But section names are
kept as it is.
For example, the course `Software Design & Architecture` will be read as
`software design architecture`.

All filters are regular expressions.

When no `-s`, `-c`, or `-cs` filters are provided, the `-c` filter is defaulted
to be `.*` so it includes all courses of all sections. So any negating filters
can be used without the `-s`, `-c`, or `-cs` filters.

### `-s section`
Use the `-s` flag to filter for sections.  
For example, to only include courses for all sections of `BSE-4`, run the
following:
```bash
./slowtable input.ods -s BSE-4 > table.html
```

To only include courses for `BSE-4A` and `BCS-4A`, run the following:
```bash
./slowtable input.ods -s BSE-4A BCS-4A > table.html
```

### `-ns section`
Use the `-ns` flag to filter _out_ a section.
For example, to exclude all Masters courses, while keeping all BS courses:
```
./slowtable input.ods -ns 'M\S\S-' > table.html
```
this uses the regex filter `M\S\S` to match any section that begins with M
followed by 2 alphabets followed by a `-`.

### `-c course`
Use the `-c` flag to filter for courses, i.e: include _all_ sections of a
specific course.
For example, to include all sections of Object Oriented Programming, run the
following:
```bash
./slowtable input.ods -c 'Object Oriented Programming' > table.html
```

### `-nc course`
Use the `-nc` flag to filter _out_ a course.
For example, to include all courses of BSE-4, except for `Data Structures`:
```bash
./slowtable input.ods -s BSE-4 -nc 'Data Structures' > table.html
```

### `-cs course (section)`
Use the `-cs` flag to include a specific course of a specific section.
For example, to include all `BSE-4A` courses, along with
`Database Systems (BSE-4B)`:
```bash
./slowtable input.ods -s BSE-4A -cs 'Database (BSE-4B)' > table.html
```

### `-ncs course (section)`
Use the `-cs` flag to exclude a specific course of a specific section.
For example, to include all `BSE-4` courses, except for
`Software Design .. (BSE-4B)`:
```bash
./slowtable input.ods -s BSE-4 -ncs 'Software Design (BSE-4B)' > table.html
```

---

## Acknowledgments
This program uses a modified version of TransientResponse's [`dlang-ods`](https://github.com/TransientResponse/dlang-ods) library.
