import hunt.xml;

void main() {
	Document document = Document.load("resources/books.xml");
	document.toFile("output.xml");
}
