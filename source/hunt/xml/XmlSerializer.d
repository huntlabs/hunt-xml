module hunt.xml.XmlSerializer;

import hunt.xml.Attribute;
import hunt.xml.Common;
import hunt.xml.Document;
import hunt.xml.Element;
import hunt.xml.Node;
import hunt.xml.Writer;

import hunt.serialization.Common;
import hunt.logging.ConsoleLogger;

import std.algorithm : map, each;
import std.array;
import std.conv;
import std.datetime;
import std.stdio;
import std.traits;

/* -------------------------------------------------------------------------- */
/*                                 Annotations                                */
/* -------------------------------------------------------------------------- */
// https://howtodoinjava.com/jaxb/jaxb-annotations/

/**
 * Excludes the field from both encoding and decoding.
 */
enum XmlIgnore;

/** 
 * 
 */
struct XmlRootElement {
    string name;
}

/** 
 * 
 */
struct XmlAttribute {
    string name;
}

/** 
 * 
 */
struct XmlElement {
    string name;
}


enum MetaTypeName = "__metatype__";

/**
 * 
 */
interface XmlSerializable {

    Element xmlSerialize();

    void xmlDeserialize(Element value);
}


/**
 * 
 */
final class XmlSerializer {

    static T toObject(T, TraverseBase traverseBase = TraverseBase.yes, bool canThrow = false)
            (string xml, T defaultValue = T.init) if (is(T == class)) {
        return toObject!(T, traverseBase, canThrow)(Document.parse(xml), defaultValue);
    }

    static T toObject(T, bool canThrow = false)
            (string xml, T defaultValue = T.init) if (!is(T == class)) {
        return toObject!(T, canThrow)(Document.parse(xml), defaultValue);
    }

    /**
     *  Converts a `Document` to an object of type `T` by filling its fields with the Document's elements.
     */
    static T toObject(T, TraverseBase traverseBase = TraverseBase.yes, bool canThrow = false)
            (Document doc, T defaultValue = T.init) if (is(T == class) && __traits(compiles, new T())) { // is(typeof(new T()))

        assert(doc !is null);
        Element element = doc.firstNode();
        return toObject!(T, traverseBase, canThrow)(element);
    }


    static T toObject(T, TraverseBase traverseBase = TraverseBase.yes, bool canThrow = false)
            (Element element, T defaultValue = T.init) if (is(T == class) && __traits(compiles, new T())) { // is(typeof(new T()))

        debug(HUNT_DEBUG_MORE) {
            tracef("Element name: %s, text: %s", element.getName(), element.getText());
        }

        auto result = new T();
        if(element is null)
            return result;

        static if(is(T : XmlSerializable)) {
            result.xmlDeserialize(element);
        } else {
            try {
                deserializeObject!(T, traverseBase)(result, element);
            } catch (XmlException e) {
                return handleException!(T, canThrow)(element, e.msg, defaultValue);
            }
        }

        return result;
    }

    /**
     * Struct
     */
    static T toObject(T, bool canThrow = false)(Document doc, T defaultValue = T.init) 
            if (is(T == struct) && !is(T == SysTime)) {

        auto result = T();
        Element element = doc.firstNode();
        if(element is null)
            return result;

        try {
            static foreach (string member; FieldNameTuple!T) {
                deserializeMember!(member)(result, element);
            }
        } catch (XmlException e) {
            return handleException!(T, canThrow)(element, e.msg, defaultValue);
        }

        return result;
    }

    /**
     * struct
     */
    static void deserializeObject(T)(ref T target, Element element) if(is(T == struct)) {
        static foreach (string member; FieldNameTuple!T) {
            // current fields
            deserializeMember!(member)(target, element);
        }
    }

    /**
     * class
     */
    static void deserializeObject(T, TraverseBase traverseBase = TraverseBase.yes)
            (T target, Element element) if(is(T == class)) {

        static foreach (string member; FieldNameTuple!T) {
            // current fields
            deserializeMember!(member)(target, element);
        }

        // super fields
        static if(traverseBase) {
            alias baseClasses = BaseClassesTuple!T;
            alias BaseType = baseClasses[0];

            static if(baseClasses.length >= 1 && !is(BaseType == Object)) {
                debug(HUNT_DEBUG_MORE) {
                    infof("deserializing fields in base %s for %s", BaseType.stringof, T.stringof);
                }
                
                alias xmlRootUDAs = getUDAs!(BaseType, XmlRootElement);
                static if(xmlRootUDAs.length > 0) {
                    enum RootNodeName = xmlRootUDAs[0].name;
                } else {
                    enum RootNodeName = BaseType.stringof;
                }

                Element baseClassElement = element.firstNode(RootNodeName);
                if(baseClassElement !is null) {
                    deserializeObject!(BaseType, traverseBase)(target, baseClassElement);
                }
            }
        }
    }

    private static void deserializeMember(string member, T, TraverseBase traverseBase = TraverseBase.yes)
            (ref T target, Element element) {
        
        alias currentMember = __traits(getMember, T, member);
        alias memberType = typeof(currentMember);
        
        debug(HUNT_DEBUG_MORE) {
            infof("deserializing member in %s: %s %s", T.stringof, memberType.stringof, member);
        }

        static if(hasUDA!(currentMember, Ignore) || hasUDA!(__traits(getMember, T, member), XmlIgnore)) {
            version(HUNT_DEBUG) {
                infof("Ignore a member: %s %s", memberType.stringof, member);
            }               
        } else {
            static if(is(memberType == interface) && !is(memberType : XmlSerializable)) {
                version(HUNT_DEBUG) warning("skipped a interface member (not XmlSerializable): " ~ member);
            } else {
                alias xmlAttributeUDAs = getUDAs!(currentMember, XmlAttribute);
                alias xmlElementUDAs = getUDAs!(currentMember, XmlElement);
                static if(xmlAttributeUDAs.length > 0 && xmlElementUDAs.length > 0) {
                    static assert(false, "Can't use both XmlAttribute and XmlElement at the same time");
                }

                static if(xmlAttributeUDAs.length > 0) {
                    enum ElementName = xmlAttributeUDAs[0].name;
                    enum elementName = (ElementName.length == 0) ? member : ElementName;
                    static if(isAssociativeArray!(memberType)) {
                        // TODO: Tasks pending completion -@zhangxueping at 2019-12-04T15:15:54+08:00
                        // 
                        __traits(getMember, target, member) = toObject!(memberType, false)(element);
                    } else {
                        Attribute att = element.firstAttribute(elementName);
                        if(att is null) {
                            version(HUNT_DEBUG) warningf("No data available for member: %s", member);
                        } else {
                            __traits(getMember, target, member) = fromAttribute!(memberType, false)(att);
                        }
                    }

                } else static if(xmlElementUDAs.length > 0) {
                    enum ElementName = xmlElementUDAs[0].name;
                    enum elementName = (ElementName.length == 0) ? member : ElementName;
                    Element ele = element.firstNode(elementName);
                    if(ele is null) {
                        version(HUNT_DEBUG) warningf("No data available for member: %s", member);
                    } else {
                        __traits(getMember, target, member) = toObject!(memberType, false)(ele);
                    }
                } else {
                    enum elementName = member;
                    Element ele = element.firstNode(elementName);
                    if(ele is null) {
                        version(HUNT_DEBUG) {
                            warningf("No data available for member: %s, type: %s", member, memberType.stringof);
                        }
                    } else {
                        static if(is(memberType == class) || (is(memberType == struct) && !is(memberType == SysTime))) {
                            ele = ele.firstNode(memberType.stringof);
                        }

                        debug(HUNT_DEBUG_MORE) {
                            if(ele is null) {
                                warningf("No data available for member: %s, type: %s", member, memberType.stringof);
                            } else {
                                tracef("Element name: %s, text: %s, elementName: %s", 
                                    ele.getName(), ele.getText(), elementName);
                            }
                        }
                        __traits(getMember, target, member) = toObject!(memberType)(ele);
                    }
                }
            }     
        }
    }

    private static T fromAttribute(T, bool canThrow = false)(Attribute attribute) {
        debug(HUNT_DEBUG_MORE) info(attribute.toString());
        string value = attribute.getValue();
        static if(isSomeString!T) {
            return value;
        } else static if(isBasicType!T) {
            return to!T(value);
        } else {
            warning("TODO: " ~ T.stringof);
            return T.init;
        }
    }


    /** 
     * XmlSerializable
     * 
     * Params:
     *   element = 
     *   T.init = 
     * Returns: 
     */
    static T toObject(T, bool canThrow = false)(Element element, T defaultValue = T.init) 
            if(is(T == interface) && is(T : XmlSerializable)) {

        Attribute attribute = element.firstAttribute(MetaTypeName);
        if(attribute is null) {
            warningf("Can't find the attribute '%s' in %s", MetaTypeName, element.getName());
            return T.init;
        }

        string typeId = attribute.getValue();
        T t = cast(T) Object.factory(typeId);
        if(t is null) {
            warningf("Can't create instance for %s", T.stringof);
        }
        t.xmlDeserialize(element);
        return t;
    }

    /**
     * 
     */
    static T toObject(T, bool canThrow = false)(Element element, T defaultValue = T.init) 
            if(is(T == SysTime)) {

        Attribute attribute = element.firstAttribute("format");
        if(attribute is null) {
            warningf("Can't find the attribute 'format' in %s", element.getName());
            return T.init;
        }

        Element txtElement = element.firstNode();
        string value = txtElement.getText();
        debug(HUNT_DEBUG_MORE) trace(txtElement.toString());

        string name = attribute.getValue();
        try {
            if(name == "std") {
                return SysTime(value.to!long());  // STD time
            } else {
                return SysTime.fromSimpleString(value);
            }
        } catch(Exception ex ){
            handleException!(T, canThrow)(element, "Wrong SysTime type", defaultValue);
        }

        return T.init;
    }

    /** 
     * string, int, long etc.
     * 
     * Params:
     *   element = 
     *   T.init = 
     * Returns: 
     */
    static T toObject(T, bool canThrow = false)(Element element, T defaultValue = T.init) 
            if (isNumeric!T || isSomeString!T) {

        Element txtElement = element;
        if(element.getType() != NodeType.Text) {
            txtElement = element.firstNode();
        }
        
        debug(HUNT_DEBUG_MORE) {
            trace(element.toString());
        }

        try {

            if(txtElement is null) {
                version(HUNT_DEBUG) warningf("No text element for [%s], so use its default.", element.toString());
                return T.init;
            } else {
                debug(HUNT_DEBUG_MORE) trace(txtElement.toString());
                string text = txtElement.getText();
                static if (isSomeString!T) {
                    return text;
                } else {
                    return text.to!T;
                }
            }
        } catch(Exception ex) {
            return handleException!(T, canThrow)(element, ex.msg, defaultValue);
        }
    }

    /** 
     * string[], byte[], int[] etc.
     * 
     * Params:
     *   element = 
     * 
     *   T.init = 
     * Returns: 
     */    
    static T toObject(T : U[], bool canThrow = false, U)
            (Element element,  U defaultValue = U.init)
            if (isSomeString!U || (isBasicType!U && !isSomeString!T)) {
        
        Appender!T appender;
        debug(HUNT_DEBUG_MORE) {
            trace(element.toString());
        }

        Element currentElement = element.firstNode();
        while(currentElement !is null) {
            Element txtElement = currentElement.firstNode();
            debug(HUNT_DEBUG_MORE) {
                trace(currentElement.toString());
                if(txtElement is null) {
                    warning("TxtElement is null");
                } else {
                    infof(txtElement.toString());
                }
            }

            string v = txtElement.getText();
            static if(isSomeString!U) {
                appender.put(v);
            } else {
                try {
                    appender.put(v.to!U());
                } catch(Exception ex) {
                    handleException(txtElement, ex.msg, defaultValue);
                }
            }
            
            currentElement = currentElement.nextSibling();
        }

        return appender.data;
    }

    /** 
     * class[] or struct[]
     * 
     * Params:
     *   element = 
     *   U.init = 
     * Returns: 
     */
    static T toObject(T : U[], bool canThrow = false, U)(Element element,  U defaultValue = U.init)
            if (is(U == class) || is(U==struct)) {

        enum TraverseBase traverseBase = TraverseBase.yes;

        debug(HUNT_DEBUG_MORE) trace(element.toString());
        Appender!T appender;
        Element currentElement = element.firstNode();

        while(currentElement !is null) {            
            debug(HUNT_DEBUG_MORE) trace(currentElement.toString());
            static if(is(U == SysTime)) {
                U v = toObject!(SysTime)(currentElement);
                appender.put(v);
            } else {
                U v = toObject!(U, traverseBase, canThrow)(currentElement);
                appender.put(v);
            }
            currentElement = currentElement.nextSibling();
        }

        return appender.data;
    }

    /** 
     * V[K]
     * 
     * Params:
     *   element = 
     *   T.init = 
     * Returns: 
     */
    static T toObject(T : V[K],  bool childNodeStyle = true, bool canThrow = false, V, K)(
            Element element, T defaultValue = T.init) if (isAssociativeArray!T) {
        
        T result;

        static if(is(V == class) || is(V == struct)) {
            warning("TODO: " ~ T.stringof); 
        }
        debug(HUNT_DEBUG_MORE) trace(element.toString());

        static if(childNodeStyle) {
            Element currentElement = element.firstNode();
            while(currentElement !is null) {
                debug(HUNT_DEBUG_MORE) trace(currentElement.toString());
                string key = currentElement.getName();

                static if(is(V == class) || is(V == struct)) {
                    // TODO: Tasks pending completion -@zhangxueping at 2019-12-04T15:01:09+08:00
                    // 
                } else {
                    Element txtElement = currentElement.firstNode();
                    debug(HUNT_DEBUG_MORE) {
                        if(txtElement is null) {
                            warning("TxtElement is null");
                        } else {
                            infof(txtElement.toString());
                        }
                    }

                    static if(isSomeString!V) {
                        string v = txtElement.getText();
                        static if(isSomeString!V) {
                            result[key] = v;
                        } else {
                            try {
                                result[key] = v.to!V();
                            } catch(Exception ex) {
                                handleException(txtElement, ex.msg, defaultValue);
                            }
                        }
                    }
                } 

                currentElement = currentElement.nextSibling();
            }

        } else {
            Attribute attr = element.firstAttribute();
            while(attr !is null) {
                debug(HUNT_DEBUG_MORE) trace(attr.toString());
                string key = attr.getName();
                string v = attr.getValue();
                
                static if(is(V == class) || is(V == struct)) {
                    // TODO: Tasks pending completion -@zhangxueping at 2019-12-04T15:01:09+08:00
                    // 
                } else static if(isSomeString!V) {
                    static if(isSomeString!V) {
                        result[key] = v;
                    } else {
                        try {
                            result[key] = v.to!V();
                        } catch(Exception ex) {
                            handleException(txtElement, ex.msg, defaultValue);
                        }
                    }
                }
                attr = attr.nextAttribute();
            }
        }

        return result;
    }
    
    private static T handleException(T, bool canThrow = false) (Element element, 
        string message, T defaultValue = T.init) {
        static if (canThrow) {
            throw new XmlException(element.toString() ~ " is not a " ~ T.stringof ~ " type");
        } else {
        version (HUNT_DEBUG)
            warningf(" %s is not a %s type. Using the defaults instead! \n Exception: %s",
                element.toString(), T.stringof, message);
            return defaultValue;
        }
    }


    /* -------------------------------------------------------------------------- */
    /*                                  toDocument                                */
    /* -------------------------------------------------------------------------- */


    /**
     * class
     */
    static Document toDocument(int depth=-1, T)(T value) if (is(T == class)) {
        enum options = SerializationOptions().depth(depth);
        return toDocument!(options)(value);
    }

    /// ditto
    static Document toDocument(SerializationOptions options, T)
            (T value) if (is(T == class)) {
        
        debug(HUNT_DEBUG_MORE) {
            info("======== current type: class " ~ T.stringof);
            tracef("%s, T: %s",
                options, T.stringof);
        }
        
        Document doc = new Document();
        Element rootNode;
        static if(is(T : XmlSerializable)) {
            // Using XmlSerializable first
            rootNode = toXmlElement!(XmlSerializable, IncludeMeta.no)("", value);
        } else {
            rootNode = serializeObject!(options, T)(value);
        }

        doc.appendNode(rootNode);
        return doc;
    }

    
    /**
     * XmlSerializable
     */
    static Document toDocument(IncludeMeta includeMeta = IncludeMeta.yes, T)
            (T value) if (is(T == interface) && is(T : XmlSerializable)) {
        
        debug(HUNT_DEBUG_MORE) {
            info("======== current type: interface " ~ T.stringof);
        }
        
        Document doc = new Document();
        Element  rootNode = toXmlElement!(XmlSerializable, includeMeta)("", value);
        doc.appendNode(rootNode);
        return doc;
    }


    /**
     * class object
     */
    static Element serializeObject(SerializationOptions options = SerializationOptions.Full, T)
            (T value) if (is(T == class)) {
        import std.traits : isSomeFunction, isType;

        debug(HUNT_DEBUG_MORE) {
            info("======== current type: class " ~ T.stringof);
            tracef("%s, T: %s", options, T.stringof);
            // tracef("traverseBase = %s, onlyPublic = %s, includeMeta = %s, T: %s",
            //     traverseBase, onlyPublic, includeMeta, T.stringof);
        }

        if (value is null) {
            version(HUNT_DEBUG) warning("value is null");
            return new Document();
        }

        alias xmlRootUDAs = getUDAs!(T, XmlRootElement);
        static if(xmlRootUDAs.length > 0) {
            enum RootNodeName = xmlRootUDAs[0].name;
        } else {
            enum RootNodeName = T.stringof;
        }

        Element rootNode = new Element(RootNodeName);
        static if(options.includeMeta) {
            Attribute attribute = new Attribute(MetaTypeName, typeid(T).name);
            rootNode.appendAttribute(attribute);
        }
        // debug(HUNT_DEBUG_MORE) pragma(msg, "======== current type: class " ~ T.stringof);
        
        // super fields
        static if(options.traverseBase) {
            alias baseClasses = BaseClassesTuple!T;
            static if(baseClasses.length >= 1) {
                debug(HUNT_DEBUG_MORE) {
                    tracef("baseClasses[0]: %s", baseClasses[0].stringof);
                }
                static if(!is(baseClasses[0] == Object)) {
                    Element superResult = serializeObject!(options, baseClasses[0])(value);
                    if(superResult !is null) {
                        rootNode.appendNode(superResult);
                    }
                }
            }
        }
        
        // current fields
		static foreach (string member; FieldNameTuple!T) {
            serializeMember!(member, options)(value, rootNode);
        }

        return rootNode;
    }


    /**
     * struct
     */
    static Document toDocument(SerializationOptions options = SerializationOptions(), T)(T value)
            if (is(T == struct) && !is(T == SysTime)) {
 
        auto result = new Document();
        debug(HUNT_DEBUG_MORE) info("======== current type: struct " ~ T.stringof);
            
        static foreach (string member; FieldNameTuple!T) {
            serializeMember!(member, options)(value, result);
        }

        return result;
    }

    /**
     * Object's memeber
     */
    private static void serializeMember(string member, 
            SerializationOptions options = SerializationOptions.Default, T)
            (T obj, Element parent) {

        // debug(HUNT_DEBUG_MORE) pragma(msg, "\tfield=" ~ member);

        alias currentMember = __traits(getMember, T, member);

        static if(options.onlyPublic) {
            static if (__traits(getProtection, currentMember) == "public") {
                enum canSerialize = true;
            } else {
                enum canSerialize = false;
            }
        } else static if(hasUDA!(currentMember, Ignore) || hasUDA!(currentMember, XmlIgnore)) {
            enum canSerialize = false;
        } else {
            enum canSerialize = true;
        }
        
        debug(HUNT_DEBUG_MORE) {
            tracef("name: %s, %s", member, options);
        }

        static if(canSerialize) {
            alias memberType = typeof(currentMember);
            debug(HUNT_DEBUG_MORE) infof("memberType: %s in %s", memberType.stringof, T.stringof);

            static if(is(memberType == interface) && !is(memberType : XmlSerializable)) {
                version(HUNT_DEBUG) warning("skipped a interface member(not XmlSerializable): " ~ member);
            } else {
                auto m = __traits(getMember, obj, member);
                alias xmlAttributeUDAs = getUDAs!(currentMember, XmlAttribute);
                alias xmlElementUDAs = getUDAs!(currentMember, XmlElement);
                static if(xmlAttributeUDAs.length > 0 && xmlElementUDAs.length > 0) {
                    static assert(false, "Cna't use both XmlAttribute and XmlElement at one time");
                }

                static if(xmlAttributeUDAs.length > 0) {
                    enum ElementName = xmlAttributeUDAs[0].name;
                    enum elementName = (ElementName.length == 0) ? member : ElementName;
                    serializeMemberAsAttribute!(options, member, elementName)(m, parent);
                } else static if(xmlElementUDAs.length > 0) {
                    enum ElementName = xmlElementUDAs[0].name;
                    enum elementName = (ElementName.length == 0) ? member : ElementName;
                    serializeMemberAsElement!(options, member, elementName)(m, parent);
                } else {
                    enum elementName = member;
                    serializeMemberAsElement!(options, member, elementName)(m, parent);
                }
            }
        } else {
            debug(HUNT_DEBUG_MORE) tracef("skipped member, name: %s", member);
        }
    }
    
    /** 
     * Object member
     * 
     * Params:
     *   name = 
     *   m = 
     * Returns: 
     */
    private static Element serializeObjectMember(SerializationOptions options = 
            SerializationOptions.Default, T)(string name, ref T m) {
        enum depth = options.depth;
        static if(depth > 0) {
            enum SerializationOptions memeberOptions = options.depth(options.depth-1);
            return toXmlElement!(memeberOptions)(name, m);
        } else static if(depth == -1) {
            return toXmlElement!(options)(name, m);
        } else {
            warningf("Reach at the specified depth: %d", depth);
            return null;
        }
    }

    private static void serializeMemberAsAttribute(SerializationOptions options, 
            string member, string elementName, T)(T m, Element parent) {
        //
        Node node;
        static if(isSomeString!T) {
            Attribute attribute = new Attribute(elementName, m);
            parent.appendAttribute(attribute);
            node = attribute;
        } else static if (isBasicType!(T)) {
            Attribute attribute = new Attribute(elementName, m.to!string());
            parent.appendAttribute(attribute);
            node = attribute;
        } else static if (is(T : V[K], V, K)) {
            Element element = toXmlElement!(options, false)(elementName, m);
            parent.appendNode(element);
            node = element;
        } else {
            static assert(false, "Only basic type or string can be set as an attribute: " ~ T.stringof);
        }

        debug(HUNT_DEBUG_MORE) {
            if(node is null)
                tracef("member: %s, node: null", member);
            else
                tracef("member: %s, node: { %s }", member, node.toString());
        }
    }

    private static void serializeMemberAsElement(SerializationOptions options, 
            string member, string elementName, T)(T m, Element parent) {
        
        assert(parent !is null, "The parent can't be null");

        Element element;
        enum depth = options.depth;
        
        static if(is(T == interface) && is(T : XmlSerializable)) {
            static if(depth == -1 || depth > 0) { element = toXmlElement!(XmlSerializable)(elementName, m); }
        } else static if(is(T == SysTime)) {
            element = toXmlElement(elementName, m);
        } else static if(isSomeString!T) {
            element = toXmlElement(elementName, m);
        } else static if(is(T == class)) {
            if(m !is null) {
                element = serializeObjectMember!(options)(elementName, m);
            }
        } else static if(is(T == struct)) {
            element = serializeObjectMember!(options)(elementName, m);
        } else static if(is(T : U[], U)) { 
            if(m is null) {
                static if(!options.ignoreNull) {
                    element = toXmlElement(elementName, m);
                }
            } else {
                static if (is(U == class) || is(U == struct) || is(U == interface)) {
                    // class[] obj; struct[] obj;
                    element = serializeObjectMember!(options)(elementName, m);
                } else {
                    element = toXmlElement(elementName, m);
                }
            }
        } else {
            element = toXmlElement(elementName, m);
        }        

        debug(HUNT_DEBUG_MORE) {
            if(element is null)
                tracef("member: %s, element: null", member);
            else
                tracef("member: %s, element: { %s }", member, element.toString());
        }

        bool canSetValue = true;
        if(element is null) {
            static if(options.ignoreNull) {
                canSetValue = false;
            }
        }

        if (canSetValue) {
            auto existNode = parent.firstNode(elementName);
            if(existNode !is null) {
                version(HUNT_DEBUG) warning("overrided field: " ~ member);
            }

            if(element !is null) {
                parent.appendNode(element);
            } else {
                warningf("skipping null element for: %s %s", T.stringof, member);
            }
        }
    }

    /**
     * SysTime
     */
    static Element toXmlElement(string name, ref SysTime value, bool asInteger=true) {
        if(name.empty) name = SysTime.stringof;
        Element result = new Element(name);
        Element txt = new Element(NodeType.Text);

        string timeFormat = "std";

        if(asInteger) {
            txt.setText(value.stdTime().to!string()); // STD time
        } else  {
            timeFormat = "simple";
            txt.setText(value.toString());
        }

        Attribute attribute = new Attribute("format", timeFormat);
        result.appendAttribute(attribute);

        result.appendNode(txt);
        return result;
    }


    /**
     * XmlSerializable
     */
    static Element toXmlElement(T, IncludeMeta includeMeta = IncludeMeta.yes)
                    (string name, T value) if (is(T == interface) && is(T : XmlSerializable)) {
        debug(HUNT_DEBUG_MORE) {
            infof("======== current type: interface = %s, Object = %s", 
                T.stringof, typeid(cast(Object)value).name);
        }

        Element result = value.xmlSerialize();
        if(result is null) {
            return null;
        }

        if(!name.empty())
            result.setName(name);
        
        static if(includeMeta) {
            Attribute attribute = new Attribute(MetaTypeName, typeid(cast(Object)value).name);
            result.appendAttribute(attribute);
            // auto itemPtr = MetaTypeName in v;
            // FIXME: Needing refactor or cleanup -@zhangxueping at 2019-12-02T15:32:27+08:00
            // 
            // if(itemPtr is null)
            //     v[MetaTypeName] = typeid(cast(Object)value).name;
        } 
        
        return result;
    }

    /** 
     * Basic types or string
     * 
     * Params:
     *   value = 
     * Returns: 
     */
    static Element toXmlElement(T)(string name, T value) if (isBasicType!T || isSomeString!(T)) {
        static if(isSomeString!(T)) {
            string v = value;
        } else {
            string v = to!string(value);
        }

        Element result = new Element(name);
        if(!v.empty) {
            Element txt = new Element(NodeType.Text);
            txt.setText(v);
            result.appendNode(txt);
        }

        return result;
    }

    /**
     * 
     */
    static Element toXmlElement(SerializationOptions options = SerializationOptions.Normal, T)
        (string name, T value) if (is(T == class)) {

        Element result = new Element(name);
        if(value !is null) {
            Element c = serializeObject!(options)(value);
            result.appendNode(c);
        }

        return result;
    }

    /**
     * 
     */
    static Element toXmlElement(SerializationOptions options = SerializationOptions.Normal, T)
        (string name, T value) if (is(T == struct)) {

        Element result = new Element(name);
        Element o = serializeObject!(options)(value);
        result.appendNode(o);

        return result;
    }

    /**
     * string[], byte[], int[] etc.
     */
    static Element toXmlElement(T : U[], U)(string name, T value)
            if ((isBasicType!U && !isSomeString!T) || isSomeString!U) {
                
        Element roolElement = new Element(name);

        if(value !is null) {
            value.map!(item => toXmlElement(U.stringof, item))
                 .each!((item) {
                        if(item !is null)  roolElement.appendNode(item);
                    })();
        }

        return roolElement;
    }

    /**
     * class[]
     */
    static Element toXmlElement(SerializationOptions options = SerializationOptions.Normal, 
            T : U[], U) (string name, T value) if(is(T : U[], U) && is(U == class)) {
        
        Element roolElement = new Element(name);
        if(value !is null) {
            value.map!(item => serializeObject!(options)(item))
                 .each!((item) {
                        if(item !is null)  roolElement.appendNode(item);
                    })();
        }

        return roolElement;
    }
    

    /**
     * struct[]
     */
    static Element toXmlElement(SerializationOptions options = SerializationOptions.Normal,
            T : U[], U)(string name, T value) if(is(U == struct)) {
                
        Element roolElement = new Element(name);

        if(value !is null) {
            static if(is(U == SysTime)) {                                
                value.map!(item => toXmlElement("", item))
                    .each!((item) {
                            if(item !is null)  roolElement.appendNode(item);
                        })();
            } else {                
                value.map!(item => serializeObject!(options)(item))()
                    .each!((item) {
                            if(item !is null)  roolElement.appendNode(item);
                        })();
            }
        }
        
        return roolElement;
    }

    /**
     * V[K]
     */
    static Element toXmlElement(SerializationOptions options = SerializationOptions.Normal, bool childNodeStyle = true,
            T : V[K], V, K)(string name, T value) {
        Element result = new Element(name);

        static if(childNodeStyle) {

            foreach (ref K key; value.keys) {

                static if(isSomeString!K) {
                    string keyName = key;
                } else {
                    string keyName = key.to!string();
                }

                static if(is(V == SysTime)) {
                    Element element = toXmlElement(keyName, value[key]);
                    result.appendNode(element);

                } else static if(is(V == class) || is(V == struct) || is(V == interface)) {
                    Element element = toXmlElement!(options)(keyName, value[key]);
                    result.appendNode(element);

                } else {
                    Element element = toXmlElement(keyName, value[key]);
                    result.appendNode(element);
                }
            }

        } else {

            foreach (ref K key; value.keys) {

                static if(isSomeString!K) {
                    string keyName = key;
                } else {
                    string keyName = key.to!string();
                }

                Attribute attribute;
                static if(isSomeString!V) {
                    attribute = new Attribute(keyName, value[key]);
                } else {
                    attribute = new Attribute(keyName, value[key].to!string());
                }
                result.appendAttribute(attribute);
            }
        }
        return result;
    }
}


alias toDocument = XmlSerializer.toDocument;
alias toObject = XmlSerializer.toObject;