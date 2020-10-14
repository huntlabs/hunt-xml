import hunt.xml;
import std.stdio;

void main() {
  //readAndWrite();
  //loadAndSave();
  //objectToXml();
  xmlToObject2();
  //	testStruct();

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

void xmlToObject2() {
  string text = `
	<response>
    <flag>success|failure</flag>
    <code>响应码</code>
    <message>响应信息</message>
    <item>
      <itemCode>商品编码, string (50) , 必填</itemCode>
      <extendProps>
        <key1>value1</key1>
        <key2>value2</key2>
      </extendProps>
    </item>

  </response>
	`;

  auto obj = toObject!(Test)(text);
  assert(obj.flag == "success|failure");
  assert(obj.code == "响应码");
  assert(obj.message == "响应信息");
  assert(obj.item !is null);
  assert(obj.item.itemCode == "商品编码, string (50) , 必填");
  assert(obj.item.extendProps.key1 == "value1");
  assert(obj.item.extendProps.key2 == "value2");

  Document doc = toDocument(obj);
  writeln(doc.toPrettyString());
}

class Item {
  this() {
  }

  @XmlElement("itemCode")
  string itemCode;

  @XmlElement("extendProps")
  Extend extendProps;
}

class Extend {
  @XmlElement("key1")
  string key1;

  @XmlElement("key2")
  string key2;
}

@XmlRootElement("response")
class Test {

  @XmlElement("flag")
  string flag;

  @XmlElement("code")
  string code;

  @XmlElement("message")
  string message;

  @XmlElement("item")
  Item item;
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
  Vector3 vector = Vector3(1, 3, 5);

  Document doc = toDocument(vector);
  writeln(doc.toPrettyString());

  Vector3 v3 = toObject!(Vector3)(doc);
}

struct Vector3 {
  float x, y, z;
}
