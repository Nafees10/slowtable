/*
This file is a modified version of Rudolph Raab's dlang-ods's ods.d, which is
under the following license:

Copyright 2018 Rudolph Raab

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
module ods;

import std.stdio, std.utf, std.file, std.algorithm, std.conv : to;
import archive.zip;
import dxml.parser;
import dxml.util: decodeXML;

private enum configSplitNo = makeConfig(SplitEmpty.no);
alias rangeT = EntityRange!(configSplitNo, string);

private string[string] getAttributeDict(rangeT range) {
	if (range.front.type != EntityType.elementStart &&
			range.front.type != EntityType.elementEmpty)
		return null;
	auto attrs = range.front.attributes;
	string[string] temp;
	while(!attrs.empty) {
		temp[attrs.front.name] = attrs.front.value;
		attrs.popFront;
	}

	return temp;
}

private uint[2] decodeAddress(ulong addr) pure {
	return [addr >> (uint.sizeof * 8), addr & uint.max];
}

private ulong encodeAddress(uint row, uint col) pure {
	return (cast(ulong)row << (uint.sizeof * 8)) | col;
}

unittest{
	foreach (uint i; 0 .. 101){
		const uint row = (uint.max * i) / 100;
		foreach (uint j; 0 .. 101){
			const uint col = (uint.max * j) / 100;
			assert (encodeAddress(row, col).decodeAddress == [row, col]);
		}
	}
}

/**
Parses an ODS file and presents the results as a lazy forward range of rows.

Usage:
```
auto sheet = new ODSSheet();
sheet.loadFromFile("file.ods", 0); //The first sheet
while(!sheet.empty) { writeln(sheet.front); sheet.popFront; }
```
*/
public class ODSSheet {
	private rangeT range;
	private string[] _row;
	private string[ulong] _pending;
	private uint _currentRow;
	private bool _endOfSheet;

	/** Retruns `true` if there are no more rows to read, and false otherwise. */
	public bool empty() {
		return range.empty || _endOfSheet;
	}

	/** Returns the current row. */
	public string[] front() {
		return _row;
	}

	/** Parses the next avaialable row, if available. */
	public void popFront() {
		if (empty) return;
		_row = parseNextRow;
	}

	/** Returns a copy of this object that can be iterated separately. */
	public ODSSheet save() {
		auto temp = new ODSSheet;
		temp._row = _row;
		temp.range = range.save();
		temp._pending = _pending.dup;
		temp._currentRow = _currentRow;
		return temp;
	}

	/**
	Reads a sheet by index from a given file.

	Params:
	filename = The name of the ODS file to read.
	sheet = The zero-based index of the sheet to read.
	*/
	public void readSheet(string filename, int sheet) {
		loadFile(filename);
		runToSheet(sheet);
		_pending = null;
		_currentRow = 0;
		_row = parseNextRow();
	}

	/**
	Reads a sheet by name from a given file.

	Params:
	filename = The name of the ODS file to read.
	sheetName = The name of the sheet to read.
	*/
	public void readSheetByName(string filename, string sheetName) {
		loadFile(filename);
		runToSheet(sheetName);
		_row = parseNextRow();
	}

	private void loadFile(string filename) {
		auto zip = new ZipArchive(read(filename));
		auto content = zip.getFile("content.xml");
		if (content is null) throw new Exception("Invalid ODS file (no content.xml)");
		auto data = content.data;
		string xml = cast(string)data;
		validate(xml);
		range = parseXML(xml);
	}

	private string parseCellContent(){
		string ret;
		string tag = range.front.name;
		if (range.front.type == EntityType.elementEmpty){
			range.popFront;
			return ret;
		}
		range.popFront;
		while (range.front.type != EntityType.elementEnd && range.front.name != tag){
			if (range.front.type == EntityType.elementStart && range.front.name == "text:p"){
				while (!(range.front.type == EntityType.elementEnd && range.front.name == "text:p")){
					if (range.front.type == EntityType.text)
						ret ~= decodeXML(range.front.text);
					range.popFront;
				}
			}
			range.popFront();
		}
		return ret;
	}

	private string[] parseNextRow() {
		if (!range.empty)
			range.popFront;
		string[] row = null;
		if (_endOfSheet)
			return null;
		while(!range.empty && !_endOfSheet) {
			const addr = encodeAddress(_currentRow, cast(uint)row.length);
			if (auto pending = addr in _pending){
				row ~= *pending;
				_pending.remove(addr);
				continue;
			}
			if (range.front.type == EntityType.elementEnd &&
					(range.front.name == "table:table-row" || range.front.name == "table:table")){
				_endOfSheet = range.front.name == "table:table";
				range.popFront;
				break;
			}
			if (range.front.name == "table:table-cell" && range.front.type != EntityType.elementEnd){
				string[string] attrs = getAttributeDict(range);
				string content = parseCellContent();
				uint hRepeat = 1, vRepeat = 1;

				if (auto repeat = "table:number-columns-spanned" in attrs){
					hRepeat = (*repeat).to!uint;
				}
				if (auto repeat = "table:number-columns-repeated" in attrs){
					hRepeat = (*repeat).to!uint > hRepeat ? (*repeat).to!uint : hRepeat;
				}

				if (auto repeat = "table:number-rows-spanned" in attrs)
					vRepeat = (*repeat).to!uint;

				foreach (i; 1 .. vRepeat)
					_pending[encodeAddress(_currentRow + i, cast(uint)row.length)] = content;
				foreach (i; 0 .. hRepeat)
					row ~= content;
			}else
				range.popFront;
		}
		_currentRow ++;
		return row;
	}
	unittest {
		string rowXML = `<table:table-row table:style-name="ro1">
		<table:table-cell office:value-type="string" calcext:value-type="string">
			<text:p>This</text:p>
		</table:table-cell>
		<table:table-cell office:value-type="string" calcext:value-type="string">
			<text:p>Is</text:p>
		</table:table-cell>
		<table:table-cell office:value-type="string" calcext:value-type="string">
			<text:p>A</text:p>
		</table:table-cell>
		<table:table-cell office:value-type="string" calcext:value-type="string">
			<text:p>Test</text:p>
		</table:table-cell>
		<table:table-cell/>
		<table:table-cell>
		<text:p><text:s text:c="2" />Some other &quot;text&quot;</text:p>
		</table:table-cell>
	</table:table-row>`;

		auto parser = new ODSSheet();
		parser.range = parseXML(rowXML);
		assert(parser.parseNextRow() == ["This", "Is", "A", "Test", "", "Some other \"text\""]);
	}


	private void runToSheet(int sheet) {
		int N = 0;
		while(!range.empty) {
			if ((range.front.type == EntityType.elementStart) && (range.front.name == "table:table")) {
				if (++N > sheet) return;
			}
			range.popFront;
		}
		throw new Exception("No sheet in ODS content");
	}
	unittest {
		string fakeXMLBody = `<?xml version="1.0" encoding="UTF-8"?>
<office:document-content>
    <office:scripts/>
    <office:font-face-decls>
        <style:font-face style:name="Calibri" svg:font-family="Calibri" style:font-family-generic="swiss"/>
        <style:font-face style:name="Liberation Sans" svg:font-family="&apos;Liberation Sans&apos;" style:font-family-generic="swiss" style:font-pitch="variable"/>
        <style:font-face style:name="Microsoft YaHei" svg:font-family="&apos;Microsoft YaHei&apos;" style:font-family-generic="system" style:font-pitch="variable"/>
        <style:font-face style:name="Segoe UI" svg:font-family="&apos;Segoe UI&apos;" style:font-family-generic="system" style:font-pitch="variable"/>
        <style:font-face style:name="Tahoma" svg:font-family="Tahoma" style:font-family-generic="system" style:font-pitch="variable"/>
    </office:font-face-decls>
    <office:automatic-styles>
        <style:style style:name="co1" style:family="table-column">
            <style:table-column-properties fo:break-before="auto" style:column-width="48.19pt"/>
        </style:style>
        <style:style style:name="ro1" style:family="table-row">
            <style:table-row-properties style:row-height="15pt" fo:break-before="auto" style:use-optimal-row-height="true"/>
        </style:style>
        <style:style style:name="ro2" style:family="table-row">
            <style:table-row-properties style:row-height="99.95pt" fo:break-before="auto" style:use-optimal-row-height="false"/>
        </style:style>
        <style:style style:name="ta1" style:family="table" style:master-page-name="PageStyle_5f_Sheet1">
            <style:table-properties table:display="true" style:writing-mode="lr-tb"/>
        </style:style>
        <style:style style:name="ce1" style:family="table-cell" style:parent-style-name="Default">
            <style:table-cell-properties style:text-align-source="fix" style:repeat-content="false" fo:wrap-option="no-wrap" fo:border="none" style:direction="ltr" style:rotation-angle="0" style:rotation-align="none" style:shrink-to-fit="false" style:vertical-align="bottom" loext:vertical-justify="auto"/>
            <style:paragraph-properties fo:text-align="center" css3t:text-justify="auto" fo:margin-left="0pt" style:writing-mode="page"/>
        </style:style>
        <style:style style:name="ce2" style:family="table-cell" style:parent-style-name="Default">
            <style:table-cell-properties style:rotation-align="none"/>
            <style:text-properties fo:color="#000000" style:text-outline="false" style:text-line-through-style="none" style:text-line-through-type="none" style:font-name="Calibri" fo:font-size="11pt" fo:font-style="normal" fo:text-shadow="none" style:text-underline-style="none" fo:font-weight="bold" style:font-size-asian="11pt" style:font-style-asian="normal" style:font-weight-asian="bold" style:font-name-complex="Calibri" style:font-size-complex="11pt" style:font-style-complex="normal" style:font-weight-complex="bold"/>
        </style:style>
        <style:style style:name="ce3" style:family="table-cell" style:parent-style-name="Default">
            <style:table-cell-properties style:text-align-source="fix" style:repeat-content="false" fo:wrap-option="no-wrap" style:direction="ltr" style:rotation-angle="0" style:rotation-align="none" style:shrink-to-fit="false" style:vertical-align="bottom" loext:vertical-justify="auto"/>
            <style:paragraph-properties fo:text-align="center" css3t:text-justify="auto" fo:margin-left="0pt" style:writing-mode="page"/>
        </style:style>
        <style:style style:name="ce4" style:family="table-cell" style:parent-style-name="Default">
            <style:table-cell-properties style:text-align-source="fix" style:repeat-content="false" fo:wrap-option="wrap" style:direction="ltr" style:rotation-angle="0" style:rotation-align="none" style:shrink-to-fit="false" style:vertical-align="bottom" loext:vertical-justify="auto"/>
            <style:paragraph-properties fo:text-align="center" css3t:text-justify="auto" fo:margin-left="0pt" style:writing-mode="page"/>
        </style:style>
        <style:style style:name="ce5" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N125">
            <style:table-cell-properties style:text-align-source="fix" style:repeat-content="false" fo:wrap-option="no-wrap" style:direction="ltr" style:rotation-angle="0" style:rotation-align="none" style:shrink-to-fit="false" style:vertical-align="bottom" loext:vertical-justify="auto"/>
            <style:paragraph-properties fo:text-align="end" css3t:text-justify="auto" fo:margin-left="0pt" style:writing-mode="page"/>
        </style:style>
        <style:style style:name="ce6" style:family="table-cell" style:parent-style-name="Default" style:data-style-name="N10126">
            <style:table-cell-properties style:rotation-align="none"/>
        </style:style>
    </office:automatic-styles>
    <office:body>
        <office:spreadsheet>
            <table:calculation-settings table:case-sensitive="false" table:automatic-find-labels="false" table:use-regular-expressions="false" table:use-wildcards="true">
                <table:iteration table:maximum-difference="0.0001"/>
            </table:calculation-settings>
            <table:table table:name="Sheet1" table:style-name="ta1">
            </table:table>
        </office:spreadsheet>
    </office:body>
</office:document-content>`;
	ODSSheet temp = new ODSSheet();
	temp.range = parseXML(fakeXMLBody);
	import std.exception: assertNotThrown;
	assertNotThrown!Exception(temp.runToSheet(0));
	}

	private void runToSheet(string sheetName) {
		while(!range.empty) {
			if ((range.front.type == EntityType.elementStart) && (range.front.name == "table:table")) {
				string[string] attrs = getAttributeDict(range);
				if (auto name = "name" in attrs) {
					if (*name == sheetName) return;
				}
			}
			range.popFront;
		}
		throw new Exception("No sheet by that name");
	}
}
