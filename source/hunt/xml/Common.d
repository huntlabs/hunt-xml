module hunt.xml.Common;

/++
+   An integer indicating which type of node this is.
+
+   Note:
+   Numeric codes up to 200 are reserved to W3C for possible future use.
+/
enum NodeType
{
    Element = 1,    //!< An element node. Name contains element name. Value contains text of first data node.
    Attribute,
    Text,           //!< A data node. Name is empty. Value contains data text.
    CDATA,          //!< A CDATA node. Name is empty. Value contains data text.
    EntityReference,
    Entity,
    ProcessingInstruction, //!< A PI node. Name contains target. Value contains instructions.
    Comment,        //!< A comment node. Name is empty. Value contains comment text.
    Document,       //!< A document node. Name and value are empty.
    DocumentType,   //!< A DOCTYPE node. Name is empty. Value contains DOCTYPE text.
   
    DocumentFragment,
    Notation,
    Declaration    //!< A declaration node. Name and value are empty. Declaration parameters (version, encoding and standalone) are in node attributes.
    //!< Value is unencoded text (used for inserting pre-rendered XML).
}


class XmlParsingException : Exception
{
    this(string msg , string text)
    {
        super(msg ~ " " ~ text);
    }

    this(string msg , char[] text)
    {
        super(msg ~ " " ~ cast(string)text.dup);
    }
}