module colors;

import utils.misc;
import std.format;

struct RGB{
	ubyte r, g, b;

	this(ubyte r, ubyte g, ubyte b) pure {
		this.r = r;
		this.g = g;
		this.b = b;
	}

	this(string hex){
		fromHex(hex);
	}

	/// decode from hex
	void fromHex(string s){
		size_t code = readHexadecimal(s);
		b = code & ubyte.max;
		g = (code >> 8) & ubyte.max;
		r = (code >> 16) & ubyte.max;
	}

	/// Returns: luminance
	@property float luminance() const pure {
		return 0.2126*r + 0.7152*g + 0.0722*b;
	}

	/// Returns: suitable foreground color for this background color
	@property RGB foreground() const pure {
		return luminance < 140 ? RGB(255, 255, 255) : RGB(0, 0, 0);
	}

	string toCSS() const pure {
		RGB fore = foreground;
		return format!"background:rgb(%d,%d,%d);color:rgb(%d,%d,%d);"(
				r, g, b, fore.r, fore.g, fore.b);
	}
}

RGB[] COLORS;

shared static this(){
	COLORS = [
		RGB("a2b9bc"),
		RGB("6b5b95"),
		RGB("b2ad7f"),
		RGB("feb236"),
		RGB("d64161"),
		RGB("86af49"),
		RGB("b5e7a0"),
		RGB("eca1a6"),
		RGB("bdcebe"),
		RGB("ada397"),
		RGB("e3eaa7"),
		RGB("405d27"),
		RGB("3e4444"),
		RGB("b9936c"),
		RGB("92a8d1"),
		RGB("034f84"),
		RGB("50394c"),
		RGB("80ced6"),
		RGB("618685"),
	];
}
