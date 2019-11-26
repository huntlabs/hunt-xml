module hunt.xml.Common;

enum NodeType
{
    Document,      //!< A document node. Name and value are empty.
    Element,       //!< An element node. Name contains element name. Value contains text of first data node.
    Data,          //!< A data node. Name is empty. Value contains data text.
    Attribute,
    CDATA,         //!< A CDATA node. Name is empty. Value contains data text.
    Comment,       //!< A comment node. Name is empty. Value contains comment text.
    Declaration,   //!< A declaration node. Name and value are empty. Declaration parameters (version, encoding and standalone) are in node attributes.
    DOCTYPE,       //!< A DOCTYPE node. Name is empty. Value contains DOCTYPE text.
    PI,            //!< A PI node. Name contains target. Value contains instructions.
    Literal        //!< Value is unencoded text (used for inserting pre-rendered XML).
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