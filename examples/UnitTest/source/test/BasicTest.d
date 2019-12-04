module test.BasicTest;

import hunt.xml;
import hunt.logging.ConsoleLogger;

import std.conv;
import std.datetime;
import std.format;

void test1()
{
    string doc_text = "<single-element/>";
	
    Document doc = Document.parse(doc_text);
    auto node = doc.firstNode();
    assert(node.getName() == "single-element");
    doc.validate();
}

void test2()
{   
    string doc_text = "<pfx:single-element/>";

    Document doc = Document.parse(doc_text);
    auto node = doc.firstNode();
    assert(node.getName() == "single-element");
    doc.validate();
}

void test3()
{
    string doc_text = "<single-element attr='one' attr=\"two\"/>";

    Document doc = Document.parse(doc_text);
    auto node = doc.firstNode();

    assert(node.getName() == "single-element");
    doc.validate();
}

void test4()
{
    string doc_text = "<single-element pfx1:attr='one' attr=\"two\"/>";

    Document doc = Document.parse(doc_text);
    auto node = doc.firstNode();

    assert(node.getName() == "single-element");
    auto attr = node.firstAttribute();
    assert(attr.xmlns() == null);
    doc.validate();

}

void test5()
{
    string doc_text = "<single-element pfx1:attr='one' pfx2:attr=\"two\" xmlns:pfx1='urn:fish' xmlns:pfx2='urn:fish'/>";

    Document doc = Document.parse(doc_text);
    auto node = doc.firstNode();

    assert(node.getName() == "single-element");
    doc.validate();
}

void test6()
{
    string doc_text = "<pfx:single xmlns:pfx='urn:xmpp:example'/>";
    Document doc = Document.parse(doc_text);
    auto node = doc.firstNode();

    assert(node.getName() == "single");
    doc.validate();
}

void test7()
{
    string doc_text = "<pfx:single xmlns:pfx='urn:xmpp:example'><pfx:firstchild/><child xmlns='urn:potato'/><pfx:child/></pfx:single>";
    Document doc = Document.parse(doc_text);

    auto node = doc.firstNode();
    assert("single" == node.getName());
    auto child = node.firstNode(null, "urn:potato");

    assert(child);
    assert("child" == child.getName());
    assert("urn:potato" == child.xmlns);

    child = node.firstNode();
    assert("firstchild" == child.getName());
    assert("urn:xmpp:example" == child.xmlns);
    //std::cout << "<" << node->prefix() << ":" << node->name() << "/> " << node->xmlns() << std::endl;

    child = node.firstNode("child");
    assert("child" == child.getName());
    assert("urn:xmpp:example" == child.xmlns);
    doc.validate();
}

void test8()
{
	string doc_text = "<pfx:single xmlns:pfx='urn:xmpp:example'><pfx:firstchild/><child xmlns='urn:potato'/><pfx:child/></pfx:single>";
	Document doc = Document.parse(doc_text);

	auto node = doc.firstNode();
	assert("single" == node.getName());
	assert("urn:xmpp:example" == node.xmlns());
	auto child = node.firstNode(null, "urn:potato");
	assert(child);
	assert("child" == child.getName());
	assert("urn:potato" == child.xmlns());
	child = node.firstNode();
	assert("firstchild" == child.getName());
	assert("urn:xmpp:example" == child.xmlns());
	//std::cout << "<" << node->prefix() << ":" << node->name() << "/> " << node->xmlns() << std::endl;
	child = node.firstNode("child");
	assert("child" == child.getName());
	assert("urn:xmpp:example" == child.xmlns());
	//std::cout << "<" << node->prefix() << ":" << node->name() << "/> " << node->xmlns() << std::endl;
	doc.validate();
}

void test10()
{
    string doc_text = "<pfx:class><student attr='11' attr2='22'><age>10</age><name>zhyc</name></student><student><age>11</age><name>spring</name></student></pfx:class>";
    Document doc = Document.parse(doc_text);

    auto node = doc.firstNode();
    assert(node.getName() == "class");
    auto student = node.firstNode();
    infof("%s", student.getType());
    Attribute attr = student.firstAttribute();
    assert(attr.getName() == "attr");
    assert(attr.getValue() == "11");

    auto attr2 = attr.nextAttribute();
    assert(attr2.getName()=="attr2");
    assert(attr2.getValue() == "22");
    infof("%s", attr2.getType());

    assert(student.getName() == "student");

    auto age = student.firstNode();
    assert(age.getName() == "age");
    assert(age.getText() == "10");
    
    infof("%s", age.getType());

    auto name = age.nextSibling();
    assert(name.getName() == "name");
    assert(name.getText() == "zhyc");
    auto student1 = student.nextSibling();

    auto age1 = student1.firstNode();
    assert(age1.getName() == "age");
    assert(age1.getText() == "11");
    auto name1 = age1.nextSibling();
    assert(name1.getName() == "name");
    assert(name1.getText() == "spring");

    assert(student1.nextSibling() is null);

    doc.validate();
}

void test11()
{
    string doc_text = "<pfx:class><student at";
    Document doc = Document.parse(doc_text);
}

void test12() {
    Document doc = new Document("Rootxxx");

    Element rootNode = new Element("Root");
    // rootNode.setParent(doc);
    doc.appendNode(rootNode);

    rootNode.appendAttribute(new Attribute("version", "1.0"));
    rootNode.appendNode(new Element("SubNode"));

    tracef(doc.toPrettyString());
}
