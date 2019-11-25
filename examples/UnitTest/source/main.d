module main;

import hunt.xml;

import std.stdio;

void test1()
{
    Document doc = new Document;
    string doc_text = "<single-element/>";
	
    doc.parse(doc_text);
    auto node = doc.firstNode();
    assert(node.getName() == "single-element");
    doc.validate();
}

void test2()
{   
    Document doc = new Document;
    string doc_text = "<pfx:single-element/>";

    doc.parse(doc_text);
    auto node = doc.firstNode();
    assert(node.getName() == "single-element");
    doc.validate();
}

void test3()
{
    Document doc = new Document;
    string doc_text = "<single-element attr='one' attr=\"two\"/>";

    doc.parse(doc_text);
    auto node = doc.firstNode();

    assert(node.getName() == "single-element");
    doc.validate();
}

void test4()
{
    Document doc = new Document;
    string doc_text = "<single-element pfx1:attr='one' attr=\"two\"/>";

    doc.parse(doc_text);
    auto node = doc.firstNode();

    assert(node.getName() == "single-element");
    auto attr = node.firstAttribute();
    assert(attr.xmlns() == null);
    doc.validate();

}

void test5()
{
    Document doc = new Document;
    string doc_text = "<single-element pfx1:attr='one' pfx2:attr=\"two\" xmlns:pfx1='urn:fish' xmlns:pfx2='urn:fish'/>";

    doc.parse(doc_text);
    auto node = doc.firstNode();

    assert(node.getName() == "single-element");
    doc.validate();
}

void test6()
{
    Document doc = new Document;
    string doc_text = "<pfx:single xmlns:pfx='urn:xmpp:example'/>";
    doc.parse(doc_text);
    auto node = doc.firstNode();

    assert(node.getName() == "single");
    doc.validate();
}

void test7()
{
    Document doc = new Document;
    string doc_text = "<pfx:single xmlns:pfx='urn:xmpp:example'><pfx:firstchild/><child xmlns='urn:potato'/><pfx:child/></pfx:single>";
    doc.parse(doc_text);

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
    Document doc = new Document;

	string doc_text = "<pfx:single xmlns:pfx='urn:xmpp:example'><pfx:firstchild/><child xmlns='urn:potato'/><pfx:child/></pfx:single>";
	doc.parse(doc_text);

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
    Document doc = new Document;
    string doc_text = "<pfx:class><student attr='11' attr2='22'><age>10</age><name>zhyc</name></student><student><age>11</age><name>spring</name></student></pfx:class>";
    doc.parse(doc_text);

    auto node = doc.firstNode();
    assert(node.getName() == "class");
    auto student = node.firstNode();
    auto attr = student.firstAttribute();
    assert(attr.getName() == "attr");
    assert(attr.getText() == "11");

    auto attr2 = attr.m_next_attribute;
    assert(attr2.getName()=="attr2");
    assert(attr2.getText() == "22");

    assert(student.getName() == "student");

    auto age = student.firstNode();
    assert(age.getName() == "age");
    assert(age.getText() == "10");
    auto name = age.m_next_sibling;
    assert(name.getName() == "name");
    assert(name.getText() == "zhyc");
    auto student1 = student.m_next_sibling;

    auto age1 = student1.firstNode();
    assert(age1.getName() == "age");
    assert(age1.getText() == "11");
    auto name1 = age1.m_next_sibling;
    assert(name1.getName() == "name");
    assert(name1.getText() == "spring");

    assert(student1.m_next_sibling is null);

    doc.validate();
}

void test11()
{
    Document doc = new Document;
    string doc_text = "<pfx:class><student at";
    doc.parse(doc_text);
}

int main()
{
    test1();
    test2();
    test3();
    test4();
    test5();
    test6();
    test7();
    test8();
    test10();
    // test11();

    return 0;
}
