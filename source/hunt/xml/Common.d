module hunt.xml.Common;

// dfmt off
/++
+   An integer indicating which type of node this is.
+
+   Note:
+   Numeric codes up to 200 are reserved to W3C for possible future use.
+/
enum NodeType {
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
// dfmt on

/** 
 * Parsing flags
 */
enum ParsingFlags {

    /// Parse flag instructing the parser to not create data nodes.
    /// Text of first data node will still be placed in value of parent element, unless EelementValues flag is also specified.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    DataNodes = 0x1,

    /// Parse flag instructing the parser to not use text of first data node as a value of parent element.
    /// Can be combined with other flags by use of | operator.
    /// Note that child data nodes of element node take precendence over its value when printing.
    /// That is, if element has one or more child data nodes <em>and</em> a value, the value will be ignored.
    /// Use DataNodes flag to prevent creation of data nodes if you want to manipulate data using values of elements.
    /// <br><br>
    EelementValues = 0x2,

    /// Parse flag instructing the parser to not place zero terminators after strings in the source text.
    /// By default zero terminators are placed, modifying source text.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    StringTerminators = 0x4,

    /// Parse flag instructing the parser to not translate entities in the source text.
    /// By default entities are translated, modifying source text.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    EntityTranslation = 0x8,

    /// Parse flag instructing the parser to disable UTF-8 handling and assume plain 8 bit characters.
    /// By default, UTF-8 handling is enabled.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    NoUtf8 = 0x10,

    /// Parse flag instructing the parser to create XML declaration node.
    /// By default, declaration node is not created.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    DeclarationNode = 0x20,

    /// Parse flag instructing the parser to create comments nodes.
    /// By default, comment nodes are not created.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    CommentNodes = 0x40,

    /// Parse flag instructing the parser to create DOCTYPE node.
    /// By default, doctype node is not created.
    /// Although W3C specification allows at most one DOCTYPE node, RapidXml will silently accept documents with more than one.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    DoctypeNode = 0x80,

    /// Parse flag instructing the parser to create PI nodes.
    /// By default, PI nodes are not created.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    PiNodes = 0x100,

    /// Parse flag instructing the parser to validate closing tag names.
    /// If not set, name inside closing tag is irrelevant to the parser.
    /// By default, closing tags are not validated.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    ValidateClosingTags = 0x200,

    /// Parse flag instructing the parser to trim all leading and trailing whitespace of data nodes.
    /// By default, whitespace is not trimmed.
    /// This flag does not cause the parser to modify source text.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    TrimWhitespace = 0x400,

    /// Parse flag instructing the parser to condense all whitespace runs of data nodes to a single space character.
    /// Trimming of leading and trailing whitespace of data is controlled by TrimWhitespace flag.
    /// By default, whitespace is not normalized.
    /// If this flag is specified, source text will be modified.
    /// Can be combined with other flags by use of | operator.
    /// <br><br>
    NormalizeWhitespace = 0x800,

    /// Parse flag to say "Parse only the initial element opening."
    /// Useful for XMLstreams used in XMPP.
    OpenOnly = 0x1000,

    /// Parse flag to say "Toss the children of the top node and parse off
    /// one element.
    /// Useful for parsing off XMPP top-level elements.
    ParseOne = 0x2000,

    /// Parse flag to say "Validate XML namespaces fully."
    /// This will generate additional errors, including unbound prefixes
    /// and duplicate attributes (with different prefices)
    ValidateXmlns = 0x4000,

    // Compound flags

    /// Parse flags which represent default behaviour of the parser.
    /// This is always equal to 0, so that all other flags can be simply ored together.
    /// Normally there is no need to inconveniently disable flags by anding with their negated (~) values.
    /// This also means that meaning of each flag is a <i>negation</i> of the default setting.
    /// For example, if flag name is NoUtf8, it means that utf-8 is <i>enabled</i> by default,
    /// and using the flag will disable it.
    /// <br><br>
    Default = 0,

    /// A combination of parse flags that forbids any modifications of the source text.
    /// This also results in faster parsing. However, note that the following will occur:
    /// <ul>
    /// <li>names and values of nodes will not be zero terminated, you have to use xml_base::name_size() and xml_base::value_size() functions to determine where name and value ends</li>
    /// <li>entities will not be translated</li>
    /// <li>whitespace will not be normalized</li>
    /// </ul>
    NonDestructive = StringTerminators | EntityTranslation,

    /// A combination of parse flags resulting in fastest possible parsing, without sacrificing important data.
    /// <br><br>
    Fastest = NonDestructive | DataNodes,

    /// A combination of parse flags resulting in largest amount of data being extracted.
    /// This usually results in slowest parsing.
    /// <br><br>
    Full = DeclarationNode | CommentNodes | DoctypeNode | PiNodes | ValidateClosingTags,
}

/** 
 * 
 */
class XmlParsingException : Exception {
    this(string msg, string text) {
        super(msg ~ " " ~ text);
    }

    this(string msg, char[] text) {
        super(msg ~ " " ~ cast(string) text.dup);
    }
}
