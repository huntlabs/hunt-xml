# rapidxml
A XML Parsing library for D Programming Language. Ported from C++ [rapidxml](http://rapidxml.sourceforge.net).

## Examples

### Parsing

```D
import hunt.xml;
import stdio;

void main()
{
    auto doc = new Document;
    string xml = "<single-element/>";
    doc.parse(xml);
    auto node = doc.firstNode();
    writeln(node.getName());
    doc.validate();
}
```

### Read/Write
```d
void readAndWrite()
{
    Document doc = Document.parse("<single-element attr1='one' attr2=\"two\"/>");
    auto node = doc.firstNode();
    assert(node.getName() == "single-element");
	assert(doc.toPrettyString() == "<single-element attr1='one' attr2='two'/>\n");
}
```

### Load/Save
```d
void loadAndSave()
{
	Document document = Document.load("resources/books.xml");
	document.toFile("output.xml");
}
```

### Serialization/Deserialization

```d
void objectToXml() {
	GreetingSettings settings = new GreetingSettings(1002, "Red");
	settings.name = "hunt";

	Document doc = toDocument(settings);
	writeln(doc.toPrettyString());
}

void xmlToObject() {
	string text = `
	<Greeting ID='1003'>
		<GreetingBase>
			<city/>
			<name>hunt</name>
		</GreetingBase>
		<Color>Red</Color>
	</Greeting>
	`;

	auto obj = toObject!(GreetingSettings)(text);
	assert(obj._id == 1003);
	assert(obj.name == "hunt");
	assert(obj.color == "Red");
}
```

### More complex xml
See [SerializerTest](examples/UnitTest/source/test/SerializerTest.d).

```xml
<Greeting>
    <GreetingBase ID='123'>
        <content>Hello</content>
    </GreetingBase>
    <privateMember>private member</privateMember>
    <settings ID='1001' __metatype__='test.SerializerTest.GreetingSettings'>
        <Greeting-SettingsBase>
            <city/>
            <name>name in base</name>
        </Greeting-SettingsBase>
        <Color>Red</Color>
        <name/>
    </settings>
    <content>Hello, world!</content>
    <creationTime format='std'>637110507901821669</creationTime>
    <nullTimes/>
    <times>
        <SysTime format='std'>637110507901821729</SysTime>
        <SysTime format='std'>637110507901821731</SysTime>
    </times>
    <bytes/>
    <members>
        <string>Alice</string>
        <string>Bob</string>
    </members>
    <guests>
        <Guest>
            <name>guest01</name>
            <age>25</age>
        </Guest>
    </guests>
    <languages>
        <en-us>Hello!</en-us>
        <zh-cn>你好！</zh-cn>
    </languages>
</Greeting>
```