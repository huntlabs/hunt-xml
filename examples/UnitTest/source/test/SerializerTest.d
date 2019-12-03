module test.SerializerTest;

import hunt.xml;
import hunt.serialization.Common;
import hunt.logging.ConsoleLogger;

struct Test {

}

class SerializerTest {

    void testAll() {
        // testBasic();
        testXmlSerializable();
    }

    void testBasic() {

    }


    // @Test void testGetAsClass01() {
    //     Greeting gt = new Greeting();
    //     gt.setPrivateMember("private member");
    //     gt.id = 123;
    //     gt.content = "Hello, world!";
    //     gt.creationTime = Clock.currTime;
    //     gt.currentTime = Clock.currStdTime;
    //     gt.setColor("Red");
    //     gt.setContent("Hello");
    //     // Document jv = XmlSerializer.toXml(gt);
    //     // // trace("====>", jv.toPrettyString(), "====");

    //     // Greeting gt1 = XmlSerializer.fromXml!(Greeting)(jv);
    //     // // trace("gt====>", gt, "====");
    //     // // trace("gt1====>", gt1, "====");
    //     // assert(gt1 !is null);
    //     // // trace(gt1.getContent());

    //     // assert(gt.getPrivateMember == gt1.getPrivateMember);
    //     // assert(gt.id == gt1.id);
    //     // assert(gt.content == gt1.content);
    //     // assert(gt.creationTime == gt1.creationTime);
    //     // assert(gt.currentTime != gt1.currentTime);
    //     // assert(0 == gt1.currentTime);
    //     // assert(gt.getColor() == gt1.getColor());
    //     // assert(gt1.getColor() == "Red");
    //     // assert(gt.getContent() == gt1.getContent());
    //     // assert(gt1.getContent() == "Hello");

    //     // Document parametersInXml;
    //     // parametersInXml["name"] = "Hunt";
    //     // string parameterModel = XmlSerializer.getItemAs!(string)(parametersInXml, "name");
    //     // assert(parameterModel == "Hunt");
    // }


    void testXmlSerializable() {
        GreetingSettings settings = new GreetingSettings();
        settings.name = "hunt";

        Document xml_class = XmlSerializer.toDocument(settings);
        info(xml_class.toPrettyString());
        // auto itemPtr = MetaTypeName in xml_class;
        // assert(itemPtr is null);

        // // 
        // ISettings isettings = settings;
        // Document xml_interface = XmlSerializer.toXml(isettings);
        // info(xml_interface.toPrettyString());

        // itemPtr = MetaTypeName in xml_interface;
        // assert(itemPtr !is null);

        // //
        // GreetingSettingsBase settingBase = settings;
        // Document xml_base = XmlSerializer.toXml(settingBase);
        // info(xml_base.toPrettyString());


        // itemPtr = MetaTypeName in xml_base;
        // assert(itemPtr !is null);
    }    

}



interface ISettings : XmlSerializable {
    string color();
    void color(string c);
}

@XmlRootElement("Greeting-SettingsBase")
abstract class GreetingSettingsBase : ISettings {

    string city;
    
    string name = "name in base";

    abstract Document xmlSerialize();
    // Document xmlSerialize() {
    //     Document v;
    //     v["_city"] = city;
    //     return v;
    // }

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

    override Document xmlSerialize() {
        return null;
        // return XmlSerializer.serializeObject!(SerializationOptions.Default.traverseBase(false))(this);
        // return XmlSerializer.serializeObject!(SerializationOptions.Default)(this);

        // Document v = super.xmlSerialize();
        // Document v;
        // v["_city"] = city;
        // v["_color"] = _color;
        // return v;        
    }
    
    override void xmlDeserialize(Document value) {
        info(value.toString());
        // _color = value["_color"].str;
    }

}