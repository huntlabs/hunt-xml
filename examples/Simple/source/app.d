import hunt.xml;

import std.file;
import std.path;
import std.stdio;

import hunt.logging.ConsoleLogger;

void main() {

	string rootPath = dirName(thisExePath());
	string fullName = buildPath(rootPath, "resources/books.xml");
	// string fullName = buildPath(rootPath, "books.xml");
	trace(fullName);
	string data = readText(fullName);
	// trace(data);
	Document document = new Document(data);


	auto file = File("output.xml", "w");
	auto ltw = file.lockingTextWriter;
	Writer!(File.LockingTextWriter, PrettyPrinters.Indenter) writer = buildWriter(ltw, PrettyPrinters.Indenter());
	// auto writer = buildWriter(ltw, PrettyPrinters.Minimalizer());

	writer.write(document);
}
