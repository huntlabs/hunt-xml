[![Build Status](https://travis-ci.org/huntlabs/hunt-xml.svg?branch=master)](https://travis-ci.org/huntlabs/hunt-xml)

# Hunt-XML
A XML library for D Programming Language.

## Features
* DOM parser: parse XML Document
* DOM writer: to string and to file
* Object serialization/seserialization


## Examples

### String parse/write
```d
import hunt.xml;

void main()
{
    Document doc = Document.parse("<single-element attr1='one' attr2=\"two\"/>");
    if(doc.validate())
    {
        auto node = doc.firstNode();
        writeln(node.getName()); // print single-element
    }
}
```

### File load/save
```d
import hunt.xml;

void main()
{
	Document document = Document.load("resources/books.xml");
	document.save("output.xml");
}
```

### Simple object serialization/deserialization

```d
@XmlRootElement("GreetingBase")
abstract class GreetingSettingsBase {
    string city;
    string name = "HuntLabs";
}

@XmlRootElement("Greeting")
class GreetingSettings : GreetingSettingsBase {

    @XmlAttribute("ID")
    int id = 1001;

    @XmlElement("Color")
    string color;
}

void objectToXml() {
	auto settings = new GreetingSettings;
	settings.name = "hunt";

	Document doc = toDocument(settings);
	writeln(doc.toString()); // print xml text
	writeln(doc.toPrettyString()); // print pretty xml text
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
	assert(obj.id == 1003);
	assert(obj.name == "hunt");
	assert(obj.color == "Red");
}
```

### Complex object serialization/deserialization
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
        <en-us>English</en-us>
        <zh-cn>中文</zh-cn>
    </languages>
</Greeting>
```