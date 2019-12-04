module test.SerializerTest;

import hunt.xml;
import hunt.serialization.Common;
import hunt.logging.ConsoleLogger;

import std.conv;
import std.datetime;
import std.format;

struct Test {

}

class SerializerTest {

    void testAll() {
        // testBasic();
        testGetAsClass01();
        // testXmlSerializable();
    }

    void testBasic() {

    }


    @Test void testGetAsClass01() {
        Greeting gt = new Greeting();
        gt.setPrivateMember("private member");
        gt.id = 123;
        gt.content = "Hello, world!";
        gt.creationTime = Clock.currTime;
        gt.currentTime = Clock.currStdTime;
        gt.setColor("Red");
        gt.setContent("Hello");
        Document xv = XmlSerializer.toDocument(gt);
        trace(xv.toPrettyString());

        // Greeting gt1 = XmlSerializer.fromXml!(Greeting)(jv);
        // // trace("gt====>", gt, "====");
        // // trace("gt1====>", gt1, "====");
        // assert(gt1 !is null);
        // // trace(gt1.getContent());

        // assert(gt.getPrivateMember == gt1.getPrivateMember);
        // assert(gt.id == gt1.id);
        // assert(gt.content == gt1.content);
        // assert(gt.creationTime == gt1.creationTime);
        // assert(gt.currentTime != gt1.currentTime);
        // assert(0 == gt1.currentTime);
        // assert(gt.getColor() == gt1.getColor());
        // assert(gt1.getColor() == "Red");
        // assert(gt.getContent() == gt1.getContent());
        // assert(gt1.getContent() == "Hello");

        // Document parametersInXml;
        // parametersInXml["name"] = "Hunt";
        // string parameterModel = XmlSerializer.getItemAs!(string)(parametersInXml, "name");
        // assert(parameterModel == "Hunt");
    }


    void testXmlSerializable() {
        Element rootNode;
        Element element;
        Attribute attribute;

        GreetingSettings settings = new GreetingSettings();
        settings.name = "hunt";

        /* ---------------------------------- class --------------------------------- */

        Document xml_class = XmlSerializer.toDocument(settings);
        // info(xml_class.toPrettyString());

        rootNode = xml_class.firstNode();
        attribute = rootNode.firstAttribute(MetaTypeName);
        assert(attribute is null);
        element = rootNode.firstNode("Color");
        assert(element !is null);

        /* -------------------------------- interface ------------------------------- */

        ISettings isettings = settings;
        Document xml_interface = XmlSerializer.toDocument(isettings);
        // info(xml_interface.toPrettyString());

        rootNode = xml_interface.firstNode();
        attribute = rootNode.firstAttribute(MetaTypeName);
        assert(attribute !is null);
        // trace(attribute.toString());

        element = rootNode.firstNode("Color");
        assert(element !is null);
        // trace(element.toString());


        /* ------------------------------- base class ------------------------------- */

        GreetingSettingsBase settingBase = settings;
        Document xml_base = XmlSerializer.toDocument(settingBase);
        info(xml_base.toPrettyString());

        rootNode = xml_interface.firstNode();
        attribute = rootNode.firstAttribute(MetaTypeName);
        assert(attribute !is null);
        // trace(attribute.toString());

        element = rootNode.firstNode("Color");
        assert(element !is null);
        // trace(element.toString());
    }    

}


/** 
 * 
 */
interface ISettings : XmlSerializable {
    string color();
    void color(string c);
}

/** 
 * 
 */
@XmlRootElement("Greeting-SettingsBase")
abstract class GreetingSettingsBase : ISettings {

    string city;
    
    string name = "name in base";

    // abstract Element xmlSerialize();
    Element xmlSerialize() {
        Element result = new Element(typeof(this).stringof);
        result.appendNode(XmlSerializer.toXmlElement("_city", city));
        return result;
    }

    void xmlDeserialize(Document value) {
        // do nothing
    }
}

@XmlRootElement("Greeting-Settings")
class GreetingSettings : GreetingSettingsBase {

    @XmlAttribute("ID")
    int id = 1001;

    @XmlElement("Color")
    string _color;

    string name;
    
    this() {
        _color = "black";
    }

    this(string color) {
        _color = color;
    }

    string color() {
        return _color;
    }

    void color(string c) {
        this._color = c;
    }

    override Element xmlSerialize() {
        
        // Method 1
        // return XmlSerializer.serializeObject!(SerializationOptions.Default.traverseBase(false))(this);
        return XmlSerializer.serializeObject!(SerializationOptions.Default)(this);

        // // Method 2
        // Element result = super.xmlSerialize();
        // result.setName(typeof(this).stringof);
        // // result.appendNode(XmlSerializer.toXmlElement("_city", city));
        
        // import std.traits;
        // alias xmlAttributeUDAs = getUDAs!(_color, XmlElement);
        // static if(xmlAttributeUDAs.length > 0) {
        //     enum ColorName = xmlAttributeUDAs[0].name;
        // } else {
        //     enum ColorName = "_color";
        // }

        // result.appendNode(XmlSerializer.toXmlElement(ColorName, _color));
        // return result;        
    }
    
    override void xmlDeserialize(Document value) {
        info(value.toString());
        // _color = value["_color"].str;
    }

}


/** 
 * 
 */
class GreetingBase {
    int id;
    private string content;

    this() {

    }

    this(int id, string content) {
        this.id = id;
        this.content = content;
    }

    void setContent(string content) {
        this.content = content;
    }

    string getContent() {
        return this.content;
    }

    override string toString() {
        return "id=" ~ to!string(id) ~ ", content=" ~ content;
    }
}

/** 
 * 
 */
class Greeting : GreetingBase {
    private string privateMember;
    private ISettings settings;

    Object.Monitor skippedMember;
    alias TestHandler = void delegate(string); 

    // FIXME: Needing refactor or cleanup -@zxp at 6/16/2019, 12:33:02 PM
    // 
    string content; // test for the same field

    SysTime creationTime;
    SysTime[] nullTimes;
    SysTime[] times;
    
    @XmlIgnore
    long currentTime;
    
    byte[] bytes;
    string[] members;
    Guest[] guests;

    string[string] languages;
    

    this() {
        super();
        initialization();
    }

    this(int id, string content) {
        super(id, content);
        this.content = ">>> " ~ content ~ " <<<";
        initialization();
    }

    private void initialization() {

        settings = new GreetingSettings();

        times = new SysTime[2];
        times[0] = Clock.currTime;
        times[1] = Clock.currTime;

        guests = new Guest[1];
        guests[0] = new Guest();
        guests[0].name = "guest01";

        languages["zh-cn"] = "你好！";
        languages["en-us"] = "Hello!";
    }

    void addGuest(string name, int age) {

        Guest g = new Guest();
        g.name = name;
        g.age = age;

        guests ~= g;
    }

    void setColor(string color) {
        settings.color = color;
    }

    string getColor() {
        return settings.color();
    }

    void voidReturnMethod() {

    }

    void setPrivateMember(string value) {
        this.privateMember = value;
    }

    string getPrivateMember() {
        return this.privateMember;
    }

    override string toString() {
        string s = format("content=%s, creationTime=%s, currentTime=%s",
                content, creationTime, currentTime);
        return s;
    }
}


class Guest {
    string name;
    int age;
}