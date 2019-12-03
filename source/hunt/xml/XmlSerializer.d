module hunt.xml.XmlSerializer;

import hunt.xml.Attribute;
import hunt.xml.Common;
import hunt.xml.Document;
import hunt.xml.Element;
import hunt.xml.Node;
import hunt.xml.Writer;

import hunt.serialization.Common;
import hunt.logging.ConsoleLogger;
import hunt.util.Common;

import std.algorithm : map;
import std.array;
import std.conv;
import std.datetime;
import std.json;
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

    Document xmlSerialize();

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
        // static if(is(T : XmlSerializable)) {
        //     // XmlSerializable first
        //     return toXmlElement!(XmlSerializable, IncludeMeta.no)(value);
        // } else {
        //     return serializeObject!(options, T)(value);
        // }
        Element rootNode = serializeObject!(options, T)(value);
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


    // /**
    //  * struct
    //  */
    // static Document toXmlElement(SerializationOptions options = SerializationOptions(), T)(T value)
    //         if (is(T == struct) && !is(T == SysTime)) {

    //     static if(is(T == Document)) {
    //         return value;
    //     } else {
    //         auto result = Document();
    //         // debug(HUNT_DEBUG_MORE) pragma(msg, "======== current type: struct " ~ T.stringof);
    //         debug(HUNT_DEBUG_MORE) info("======== current type: struct " ~ T.stringof);
                
    //         static foreach (string member; FieldNameTuple!T) {
    //             serializeMember!(member, options)(value, result);
    //         }

    //         return result;
    //     }
    // }

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

        Element element;
        enum depth = options.depth;
        // static if(is(T == interface) && is(T : XmlSerializable)) {
        //     static if(depth == -1 || depth > 0) { result = toXmlElement!(XmlSerializable)(m);}
        // } else static if(is(T == SysTime)) {
        //     result = toXmlElement!SysTime(m);
        // // } else static if(isSomeString!T) {
        // //     result = toXmlElement(m);
        // } else static if(is(T == class)) {
        //     if(m !is null) {
        //         result = serializeObjectMember!(options)(m);
        //     }
        // } else static if(is(T == struct)) {
        //     result = serializeObjectMember!(options)(m);
        // } else static if(is(T : U[], U)) { 
        //     if(m is null) {
        //         static if(!options.ignoreNull) {
        //             static if(isSomeString!T) {
        //                 result = toXmlElement(m);
        //             } else {
        //                 result = Document[].init;
        //             }
        //         }
        //     } else {
        //         static if (is(U == class) || is(U == struct) || is(U == interface)) {
        //             // class[] obj; struct[] obj;
        //             result = serializeObjectMember!(options)(m);
        //         } else {
        //             result = toXmlElement(m);
        //         }
        //     }
        // } else {
        //     result = toXmlElement(m);
        // }

        element = toTextElement(m);
        
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
            // FIXME: Needing refactor or cleanup -@zhangxueping at 2019-12-02T14:09:36+08:00
            // 
            // if(parent !is null) {
            //     auto jsonItemPtr = member in parent;
            //     if(jsonItemPtr !is null) {
            //         version(HUNT_DEBUG) warning("overrided field: " ~ member);
            //     }
            // }
            Element nameElement = new Element(elementName);
            if(element !is null) {
                nameElement.appendNode(element);
            }
            parent.appendNode(nameElement);
        }
    }

    // private static Document serializeObjectMember(SerializationOptions options = 
    //         SerializationOptions.Default, T)(ref T m) {
    //     enum depth = options.depth;
    //     static if(depth > 0) {
    //         enum SerializationOptions memeberOptions = options.depth(options.depth-1);
    //         return toXmlElement!(memeberOptions)(m);
    //     } else static if(depth == -1) {
    //         return toXmlElement!(options)(m);
    //     } else {
    //         return Document.init;
    //     }
    // }

    // /**
    //  * SysTime
    //  */
    // static Document toXmlElement(T)(T value, bool asInteger=true) if(is(T == SysTime)) {
    //     if(asInteger)
    //         return Document(value.stdTime()); // STD time
    //     else 
    //         return Document(value.toString());
    // }

    // // static Nullable!Document toXmlElement(N : Nullable!T, T)(N value) {
    // //     return value.isNull ? Nullable!Document() : Nullable!Document(toXmlElement!T(value.get()));
    // // }

    // // static Document toXmlElement(T)(T value) if (is(T == Document)) {
    // //     return value;
    // // }

    /**
     * XmlSerializable
     */
    static Document toXmlElement(T, IncludeMeta includeMeta = IncludeMeta.yes)
                    (T value) if (is(T == interface) && is(T : XmlSerializable)) {
        debug(HUNT_DEBUG_MORE) {
            infof("======== current type: interface = %s, Object = %s", 
                T.stringof, typeid(cast(Object)value).name);
        }

        Document v = value.xmlSerialize();
        static if(includeMeta) {
            auto itemPtr = MetaTypeName in v;
            // FIXME: Needing refactor or cleanup -@zhangxueping at 2019-12-02T15:32:27+08:00
            // 
            // if(itemPtr is null)
            //     v[MetaTypeName] = typeid(cast(Object)value).name;
        }
        // TODO: Tasks pending completion -@zhangxueping at 2019-09-28T07:45:09+08:00
        // remove the MetaTypeName memeber
        debug(HUNT_DEBUG_MORE) trace(v.toString());
        return v;
    }

    /** 
     * 
     * Params:
     *   value = 
     * Returns: 
     */
    static Element toTextElement(T)(T value) if (isBasicType!T || isSomeString!(T)) {
        static if(isSomeString!(T)) {
            warning("text: ", value);
            string v = value;
        } else {
            string v = to!string(value);
            warning("text: ", v);
        }

        if(v.empty) return null;

        Element result = new Element(NodeType.Text);
        result.setText(v);

        return result;
    }

    // /**
    //  * string[]
    //  */
    // static Document toXmlElement(T)(T value)
    //         if (is(T : U[], U) && (isBasicType!U || isSomeString!U)) {
    //     return Document(value);
    // }

    // /**
    //  * class[]
    //  */
    // static Document toXmlElement(SerializationOptions options = SerializationOptions.Normal, 
    //         T : U[], U) (T value) if(is(T : U[], U) && is(U == class)) {
    //     if(value is null) {
    //         return Document(Document[].init);
    //     } else {
    //         return Document(value.map!(item => toXmlElement!(options)(item))()
    //                 .map!(json => json.isNull ? Document(null) : json).array);
    //     }
    // }
    

    // /**
    //  * struct[]
    //  */
    // static Document toXmlElement(SerializationOptions options = SerializationOptions.Normal,
    //         T : U[], U)(T value) if(is(U == struct)) {
    //     if(value is null) {
    //         return Document(Document[].init);
    //     } else {
    //         static if(is(U == SysTime)) {
    //             return Document(value.map!(item => toXmlElement(item))()
    //                     .map!(json => json.isNull ? Document(null) : json).array);
    //         } else {
    //             return Document(value.map!(item => toXmlElement!(options)(item))()
    //                     .map!(json => json.isNull ? Document(null) : json).array);
    //         }
    //     }
    // }

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