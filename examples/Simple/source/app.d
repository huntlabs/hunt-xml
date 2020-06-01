import hunt.xml;
import std.stdio;

void main() {
	readAndWrite();
	loadAndSave();
	objectToXml();
	xmlToObject();
	testStruct();

}

// read/write
void readAndWrite() {
    Document doc = Document.parse("<single-element attr1='one' attr2=\"two\"/>");
    auto node = doc.firstNode();
    assert(node.getName() == "single-element");
	assert(doc.toPrettyString() == "<single-element attr1='one' attr2='two'/>\n");
}

// load/save
void loadAndSave() {
	Document document = Document.load("resources/books.xml");
	document.save("output.xml");
}

// Serialization
void objectToXml() {
	GreetingSettings settings = new GreetingSettings(1002, "Red");
	settings.name = "hunt";

	Document doc = toDocument(settings);
	writeln(doc.toPrettyString());

/*	
	<Greeting ID='1002'>
		<GreetingBase>
			<city/>
			<name>hunt</name>
		</GreetingBase>
		<Color>Red</Color>
	</Greeting>
*/	
}


// Deserialization
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


/** 
 * 
 */
@XmlRootElement("GreetingBase")
abstract class GreetingSettingsBase {
    string city;
    string name = "HuntLabs";
}

@XmlRootElement("Greeting")
class GreetingSettings : GreetingSettingsBase {

    @XmlAttribute("ID")
    int _id = 1001;

    @XmlElement("Color")
    private string _color;
    
    this() {
        _color = "black";
    }

    this(int id, string color) {
		_id = id;
        _color = color;
    }

    string color() {
        return _color;
    }

    void color(string c) {
        this._color = c;
    }
}

void testStruct() {
	Vector3 vector = Vector3(1,3,5);

	Document doc = toDocument(vector);
	writeln(doc.toPrettyString());	
}

struct Vector3 {
	float x, y, z; 
} 
