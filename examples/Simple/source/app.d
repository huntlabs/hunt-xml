import hunt.xml;
import std.stdio;

import hunt.logging;

import std.array : Appender;

void main() {
	// readAndWrite();
	// loadAndSave();
	// objectToXml();
	// xmlToObject();
	// testStruct();
	// escapeTest();
	iterationNodes();
}

void escapeTest() {
	string text = `
        <receiverInfo>
            <detailAddress>602&amp;#35;.</detailAddress>
            <detailAddress>602&#35;.</detailAddress>
        </receiverInfo>	
`;


	Document doc = Document.parse(text);

	writeln(doc.toPrettyString());

}

void iterationNodes() {

	string text = `
<xml>
<appid><![CDATA[wx50b8ff9117eb0d67]]></appid>
<transaction_id><![CDATA[4200001427202205084516212946]]></transaction_id>
<trade_type><![CDATA[JSAPI]]></trade_type>
<total_fee>800</total_fee>
<time_end><![CDATA[20220508155047]]></time_end>
<sign><![CDATA[3B87F4295E36E7E5EBE128D9B64638D5]]></sign>
<return_code><![CDATA[SUCCESS]]></return_code>
<result_code><![CDATA[SUCCESS]]></result_code>
<out_trade_no><![CDATA[011651996147427170]]></out_trade_no>
<openid><![CDATA[opEGh5a8ZBYO0GTx9lwodZ2edfYo]]></openid>
<nonce_str><![CDATA[FPI6Da2bJOqQyeIN]]></nonce_str>
<mch_id><![CDATA[1607490068]]></mch_id>
<is_subscribe><![CDATA[N]]></is_subscribe>
<fee_type><![CDATA[CNY]]></fee_type>
<coupon_id_0><![CDATA[33390755975]]></coupon_id_0>
<coupon_fee_0><![CDATA[600]]></coupon_fee_0>
<coupon_fee>600</coupon_fee>
<coupon_count><![CDATA[1]]></coupon_count>
<cash_fee><![CDATA[200]]></cash_fee>
<bank_type><![CDATA[COMM_DEBIT]]></bank_type>
</xml>
`;

	Document doc = Document.parse(text);

	Element el = doc.firstNode;

	string key;
	string value;
	string[string] nodes;

	el = el.firstNode();
	while(el !is null) {

		Element subNode = el.firstNode();
		// tracef("type: %s", subNode.getType());

		key = el.getName();

		if(subNode.getType() == NodeType.Text) {
			value = el.getText();
		} else if(subNode.getType() == NodeType.CDATA) {
			Appender!string appender = Appender!string();
			auto writer = buildWriter(appender, PrettyPrinters.Minimalizer());
			writer.writeNode(subNode);
			value = appender.data;
		} else {
			throw new Exception("Can't handle this xml");
		}
		writefln("key: %s, value: %s", key, value);
		nodes[key] = value;

		el = el.nextSibling();
	}

	writeln(nodes);
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

	Vector3 v3 = toObject!(Vector3)(doc);
}

struct Vector3 {
	float x, y, z; 
} 
