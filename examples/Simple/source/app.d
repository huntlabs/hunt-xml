import hunt.xml;

import std.file;
import std.path;
import std.stdio;

import hunt.logging.ConsoleLogger;

import std.ascii;

import hunt.xml.Internal;

void main() {

	string rootPath = dirName(thisExePath());
	string fullName = buildPath(rootPath, "resources/books.xml");
	// string fullName = buildPath(rootPath, "books.xml");
	trace(fullName);
	string data = readText(fullName);
	// trace(data);
	Document document = Document.parse(data);

	auto file = File("output.xml", "w");
	auto ltw = file.lockingTextWriter;
	Writer!(File.LockingTextWriter, PrettyPrinters.Indenter) writer = buildWriter(ltw, PrettyPrinters.Indenter());
	// auto writer = buildWriter(ltw, PrettyPrinters.Minimalizer());

	writer.write(document);

	// string str = document.toString();
	// trace(str);

	// str = document.toPrettyString();
	// trace(str);

	// document.toFile("output.xml");

}
