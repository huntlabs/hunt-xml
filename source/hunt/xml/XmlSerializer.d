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

    void xmlDeserialize(Document value);
}


/**
 * 
 */
final class XmlSerializer {



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

        static if(is(T == Document)) {
            return value;
        } else {
            auto result = Document();
            debug(HUNT_DEBUG_MORE) info("======== current type: struct " ~ T.stringof);
                
            static foreach (string member; FieldNameTuple!T) {
                serializeMember!(member, options)(value, result);
            }

            return result;
        }
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
    

    private static void serializeMemberAsAttribute(SerializationOptions options, 
            string member, string elementName, T)(T m, Element parent) {
        //
        Attribute attribute;
        static if(isSomeString!T) {
            attribute = new Attribute(elementName, m);
            parent.appendAttribute(attribute);
        } else static if (isBasicType!(T)) {
            attribute = new Attribute(elementName, m.to!string());
            parent.appendAttribute(attribute);
        } else {
            static assert(false, "Only basic type or string can be set as an attribute: " ~ T.stringof);
        }

        debug(HUNT_DEBUG_MORE) {
            if(attribute is null)
                tracef("member: %s, attribute: null", member);
            else
                tracef("member: %s, attribute: { %s }", member, attribute.toString());
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
            element = toXmlElement!SysTime(elementName, m);
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
                    static if(isSomeString!T) {
                        element = toXmlElement(elementName, m);
                    } else {
                        // TODO: Tasks pending completion -@zhangxueping at 2019-12-03T14:10:45+08:00
                        // 
                        warning("TODO: " ~ T.stringof);
                    }
                }
            } else {
                static if (is(U == class) || is(U == struct) || is(U == interface)) {
                    // class[] obj; struct[] obj;
                    element = serializeObjectMember!(options)(elementName, m);
                } else {
                    // element = toXmlElement(m);
                    warning("TODO: " ~ U.stringof);
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

    /**
     * SysTime
     */
    static Element toXmlElement(T)(string name, T value, bool asInteger=true) if(is(T == SysTime)) {
        Element result = new Element(name);
        Element txt = new Element(NodeType.Text);

        if(asInteger)
            txt.setText(value.stdTime().to!string()); // STD time
        else 
            txt.setText(value.toString());

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

    // /**
    //  * string[]
    //  */
    // static Document toXmlElement(T)(T value)
    //         if (is(T : U[], U) && (isBasicType!U || isSomeString!U)) {
    //     return Document(value);
    // }

    /**
     * class[]
     */
    static Element toXmlElement(SerializationOptions options = SerializationOptions.Normal, 
            T : U[], U) (string name, T value) if(is(T : U[], U) && is(U == class)) {
        
        Element roolElement = new Element(name);
        if(value !is null) {
            // Element[] elements = value.map!(item => serializeObject!(options)(item))().array;

            // foreach(Element el; elements) {
            //     if(el !is null) {
            //         roolElement.appendNode(el);
            //     }
            // }
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
                // return Document(value.map!(item => toXmlElement(item))()
                //         .map!(json => json.isNull ? Document(null) : json).array);
                
                // value.map!(item => toXmlElement!(SysTime)(item))()
                //     .map!((item) {
                //             if(item !is null)  roolElement.appendNode(el);
                //         })();
                warningf("TODO: SysTime[] %s", name);
            } else {
                // return Document(value.map!(item => toXmlElement!(options)(item))()
                //         .map!(json => json.isNull ? Document(null) : json).array);
                
                value.map!(item => serializeObject!(options)(item))()
                    .map!((item) {
                            if(item !is null)  roolElement.appendNode(el);
                        })();
            }
        }
        
        return roolElement;
    }

    // /**
    //  * U[K]
    //  */
    // static Document toXmlElement(SerializationOptions options = SerializationOptions.Normal,
    //         T : U[K], U, K)(T value) {
    //     auto result = Document();

    //     foreach (key; value.keys) {
    //         static if(is(U == SysTime)) {
    //             auto json = toXmlElement(value[key]);
    //         } else static if(is(U == class) || is(U == struct) || is(U == interface)) {
    //             auto json = toXmlElement!(options)(value[key]);
    //         } else {
    //             auto json = toXmlElement(value[key]);
    //         }
    //         result[key.to!string] = json.isNull ? Document(null) : json;
    //     }

    //     return result;
    // }
}


alias toDocument = XmlSerializer.toDocument;