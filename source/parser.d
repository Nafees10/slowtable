module parser;

import std.algorithm,
			 std.regex,
			 std.string,
			 std.datetime,
			 std.conv,
			 std.json;

import ods;

import utils.misc : isAlphabet, isNum;

struct Entry{
	/// starting cell index
	size_t index;
	/// width
	size_t width;
	/// ending index (last index occupied by this)
	@property size_t lastIndex() const pure {
		return index + width - 1;
	}
	/// name
	string name;
}

Entry[] parseEntries(string[] row){
	Entry[] ret;
	for (size_t i = 0; i < row.length;){
		size_t count = 1;
		while (i + count < row.length && row[i + count] == row[i])
			++count;
		ret ~= Entry(i, count, row[i]);
		i += count;
	}
	return ret;
}
