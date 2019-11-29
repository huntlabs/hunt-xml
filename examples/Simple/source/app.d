import hunt.xml;

import std.file;
import std.path;

void main() {
	string rootPath = dirName(thisExePath());
	string fullName = buildPath(rootPath, "resources/books.xml");
	string data = readText(fullName);
	Document document = Document.parse(data);
	document.toFile("output.xml");
}
