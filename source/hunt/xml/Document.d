module hunt.xml.Document;

import hunt.xml.Attribute;
import hunt.xml.Common;
import hunt.xml.Element;
import hunt.xml.Node;
import hunt.xml.Internal;

import hunt.xml.Writer;

import std.array : Appender;

/** 
 * 
 */
class Document : Element
{
    this() {
        m_type = NodeType.Document;
    }

    this(string text) {
        m_type = NodeType.Document;
        parse(text);
    }

    string parse(int Flags = 0)(string stext , Document parent = null)
    {
        this.removeAllNodes();
        this.removeAllAttributes();
        this.m_parent = parent ? parent.m_first_node : null;
        char[] text = cast(char[])stext.dup;

        parseBom(text);

        size_t index = 0;
        size_t length = text.length;
        while(1)
        {
            skip!(WhitespacePred)(text); 
            if(index >= text.length)
                break;
            if(text[index] =='<')
            {
                ++index;
                text = text[index .. $];
                Element  node = parseNode!(Flags)(text);
                if(node)
                {
                    this.appendNode(node);
                    if(Flags & (parse_open_only | parse_parse_one))
                    {
                        if(node.m_type == NodeType.Comment)
                            break;
                    }
                }
            }
            else
                throw new XmlParsingException("expected <", text);
        }

        if(!firstNode())
            throw new XmlParsingException("no root element", text[index .. $ ]);

        return string.init;
    }

    private Element parseNode(int Flags)(ref char[] text)
    {
        switch(text[0])
        {
            default:
                return parseElement!Flags(text);

            case '?':
                text = text[1 .. $ ];
                if(
                    ((text[0] == 'x' ) || (text[0] == 'X')) &&
                ((text[0] == 'm' ) || (text[0] == 'M')) &&
                ((text[0] == 'l' ) || (text[0] == 'L')) &&
                WhitespacePred.test(text[3]))
                {
                    text = text[4 .. $];
                    return parseXmlDeclaration!Flags(text);
                }
                else
                {
                    return parsePI!Flags(text);
                }

            case '!':
                switch(text[1])
                {
                case '-':
                    if(text[2] == '-')
                    {
                        text = text[3 .. $ ];
                        return parseComment!Flags(text);
                    } 
                    break;
                case ('['):
                    if (text[2] == ('C') && text[3] == ('D') && text[4] == ('A') &&
                        text[5] == ('T') && text[6] == ('A') && text[7] == ('['))
                    {
                        // '<![CDATA[' - cdata
                        text = text[8 .. $ ];     // Skip '![CDATA['
                        return parseCdata!Flags(text);
                    }
                    break;

                // <!D
                case ('D'):
                    if (text[2] == ('O') && text[3] == ('C') && text[4] == ('T') &&
                        text[5] == ('Y') && text[6] == ('P') && text[7] == ('E') &&
                        WhitespacePred.test(text[8]))
                    {
                        // '<!DOCTYPE ' - doctype
                        text = text[9 .. $ ];      // skip '!DOCTYPE '
                        return parseDoctype!Flags(text);
                    }
                    break;
                default:
                    break;

                } 

                 text = text[1 .. $ ];     // Skip !
                while (text[0] != ('>'))
                {
                    if (text == null)
                        throw new XmlParsingException("unexpected end of data", text);
                    text = text[1 .. $ ];
                }
                text = text[1 .. $ ];     // Skip '>'
                return null;   // No node recognized

        }
    }

    private Element parseCdata(int Flags)(ref char[] text)
    {
        // If CDATA is disabled
        if (Flags & parse_no_data_nodes)
        {
            // Skip until end of cdata
            while (text[0] != ']' || text[1] != ']' || text[2] != '>')
            {
                if (!text[0])
                    throw new XmlParsingException("unexpected end of data", text);
                text = text[1 .. $];
            }
            text = text[3 .. $];      // Skip ]]>
            return null;       // Do not produce CDATA node
        }

        // Skip until end of cdata
        char[] value = text;
        while (text[0] != (']') || text[1] != (']') || text[2] != ('>'))
        {
            if (!text[0])
                throw new XmlParsingException("unexpected end of data", text);
            text = text[1 .. $ ];
        }

        // Create new cdata node
        Element cdata = new Element(NodeType.CDATA);
        cdata.m_value = cast(string)value[ 0 .. value.length - text.length].dup;

        // Place zero terminator after value

        text = text[3 .. $ ];      // Skip ]]>
        return cdata;
    }

    private char parseAndAppendData(int Flags)(Element node, ref char []text, char[] contents_start)
    {
        // Backup to contents start if whitespace trimming is disabled
        if (!(Flags & parse_trim_whitespace))
            text = contents_start;

        // Skip until end of data
        char [] value = text;
        char []end;
        if (Flags & parse_normalize_whitespace)
            end = skipAndExpandCharacterRefs!(TextPred, TextPureWithWsPred, Flags)(text);
        else
            end = skipAndExpandCharacterRefs!(TextPred, TextPureNoWsPred, Flags)(text);

        // Trim trailing whitespace if flag is set; leading was already trimmed by whitespace skip after >
        if (Flags & parse_trim_whitespace)
        {
            if (Flags & parse_normalize_whitespace)
            {
                // Whitespace is already condensed to single space characters by skipping function, so just trim 1 char off the end
                if (end[-1] == ' ')
                    end = end[-1 .. $];
            }
            else
            {
                // Backup until non-whitespace character is found
                while (WhitespacePred.test(end[-1]))
                    end = end[-1 .. $ - 1];
            }
        }

        // If characters are still left between end and value (this test is only necessary if normalization is enabled)
        // Create new data node
        if (!(Flags & parse_no_data_nodes))
        {
            Element data = new Element(NodeType.Text);
            data.m_value = cast(string)value[0 .. value.length - end.length].dup;
            node.appendNode(data);
        }

        // Add data to parent node if no data exists yet
        if (!(Flags & parse_no_element_values))
            if (node.m_value.length == 0)
                node.m_value = cast(string)value[0 ..value.length - end.length];

        // Place zero terminator after value
        if (!(Flags & parse_no_string_terminators))
        {
            ubyte ch = text[0];
            end[0] ='\0';
            return ch;      // Return character that ends data; this is required because zero terminator overwritten it
        }
        else
        // Return character that ends data
        return text[0];
    }

    private Element parseElement(int Flags)(ref char[] text)
    {
        Element element = new Element();
        char[] prefix = text;
        //skip ElementNamePred
        skip!(ElementNamePred)(text);
        if(text == prefix)
            throw new XmlParsingException("expected element name or prefix", text);
        if(text.length >0 && text[0] == ':')
        {
            element.m_prefix = prefix[0 .. prefix.length - text.length].dup;
            text = text[1 .. $ ];
            char[] name = text;
            //skip NodeNamePred
            skip!(NodeNamePred)(text);
            if(text == name)
                throw new XmlParsingException("expected element local name", text);
            element.m_name = name[0 .. name.length - text.length].dup;
        }
        else{
            element.m_name = prefix[ 0 .. prefix.length - text.length].dup;            
        }

        //skip WhitespacePred
        skip!(WhitespacePred)(text);
        parseNodeAttributes!(Flags)(text , element);
        if(text.length > 0 && text[0] == '>')
        {
            text = text[1 .. $];
            char[] contents = text;
            char[] contents_end = null;
            if(!(Flags & parse_open_only))
            {    
                contents_end = parseNodeContents!(Flags)(text , element);
            }
            if(contents_end.length != contents.length )
            {
                element.m_contents = cast(string)contents[0 .. contents.length - contents_end.length].dup;
            }
        }
        else if(text.length > 0 && text[0] == '/')
        {
            text = text[1 .. $ ];
            if(text[0] != '>')
                throw new XmlParsingException("expected >", text);

            text = text[1 .. $ ];

            if(Flags & parse_open_only)
                throw new XmlParsingException("open_only, but closed", text);
        }
        else 
            throw new XmlParsingException("expected >", text);
        // Place zero terminator after name 
        // no need.
        return element;
    }

    private char[] parseNodeContents(int Flags)(ref char[] text , Element node)
    {
        char[] retval;

        while(1)
        {
            char[] contents_start = text;
            skip!(WhitespacePred)(text);
            char next_char = text[0];

            after_data_node:

            switch(next_char)
            {
                case '<':
                if(text[1] == '/')
                {
                    retval = text;
                    text = text[2 .. $ ];
                    if(Flags & parse_validate_closing_tags)
                    {
                        string closing_name = cast(string)text.dup;
                        skip!(NodeNamePred)(text);
                        if(closing_name == node.m_name)
                            throw new XmlParsingException("invalid closing tag name", text);
                    }
                    else
                    {
                        skip!(NodeNamePred)(text);
                    }

                    skip!(WhitespacePred)(text);
                    if(text[0] != '>')
                        throw new XmlParsingException("expected >", text);
                    text = text[1 .. $];
                    if(Flags & parse_open_only)
                        throw new XmlParsingException("Unclosed element actually closed.", text);

                    return retval;
                }
                else
                {
                    text = text[1 .. $ ];
                    if(Element child = parseNode!(Flags & ~parse_open_only)(text))
                        node.appendNode(child);
                }
                break;
            default:
                 next_char = parseAndAppendData!(Flags)(node, text, contents_start);
                goto after_data_node;   // Bypass regular processing after data nodes
            }
        }

        return null;
    }

    private void parseNodeAttributes(int Flags)(ref char[] text , Element node)
    {
        int index = 0;

        while(text.length > 0 && AttributeNamePred.test(text[0]))
        {
            char[] name = text;
            text = text[1 .. $ ];
            skip!(AttributeNamePred)(text);
            if(text == name)
                throw new XmlParsingException("expected attribute name", name);

            Attribute attribute = new Attribute();
            attribute.m_name = cast(string)name[0 .. name.length - text.length].dup;

            node.appendAttribute(attribute);

            skip!(WhitespacePred)(text);

            if(text.length ==0 || text[0] != '=')
                throw new XmlParsingException("expected =", text);

            text = text[1 .. $ ];

            skip!(WhitespacePred)(text);

            char quote = text[0];
            if(quote != '\'' && quote != '"')
                throw new XmlParsingException("expected ' or \"", text);

            text = text[1 .. $ ];
            char[] value = text ;
            char[] end;
            const int AttFlags = Flags & ~parse_normalize_whitespace;

            if(quote == '\'')
                end = skipAndExpandCharacterRefs!(AttributeValuePred!'\'' , AttributeValuePurePred!('\'') , AttFlags)(text);
            else
                end = skipAndExpandCharacterRefs!(AttributeValuePred!('"') , AttributeValuePurePred!('"') , AttFlags)(text);

            attribute.m_value = cast(string)value[0 .. value.length - end.length].dup;

            if(text.length > 0 && text[0] != quote)
                throw new XmlParsingException("expected ' or \"", text);

            text = text[1 .. $ ];

            skip!(WhitespacePred)(text);
        }
    }

    private static void skip(T )(ref char[] text)
    {

        char[] tmp = text;
        while(tmp.length > 0 && T.test(tmp[0]))
        {
            tmp = tmp[1 .. $];    
        }
        text = tmp;
    }

    private void parseBom(ref char[] text)
    {
        if(text[0] == 0xEF 
        && text[1] == 0xBB 
        && text[2] == 0xBF)
        {
            text = text[3 .. $ ];
        }
    }

    private Element parseXmlDeclaration(int Flags)(ref char[] text)
    {
        // If parsing of declaration is disabled
        if (!(Flags & parse_declaration_node))
        {
            // Skip until end of declaration
            while (text[0] != '?' || text[1] != '>')
            {
                if (!text[0]) 
                throw new XmlParsingException("unexpected end of data", text);
                text = text[1 .. $ ];
            }
            text = text[2 .. $ ];    // Skip '?>'
            return null;
        }

        static if (Flags != 0)
        // Create declaration
        {
            Element declaration = new Element(NodeType.Declaration);

            // Skip whitespace before attributes or ?>
            skip!WhitespacePred(text);
            // Parse declaration attributes
            parseNodeAttributes!Flags(text, declaration);

            // Skip ?>
            if (text[0] != '?' || text[1] != '>') 
                throw new XmlParsingException("expected ?>", text);
            text = text[2 .. $ ];

            return declaration;
        }
    }

    private Element parsePI(int Flags)(ref char[] text)
    {
        // If creation of PI nodes is enabled
        if (Flags & parse_pi_nodes)
        {
            // Create pi node
            Element pi = new Element(NodeType.ProcessingInstruction);

            // Extract PI target name
            char[] name = text;
            skip!NodeNamePred(text);
            if (text == name) 
                throw new XmlParsingException("expected PI target", text);
            pi.m_name = cast(string)name[0 .. name.length - text.length].dup;

            // Skip whitespace between pi target and pi
            skip!WhitespacePred(text);

            // Remember start of pi
            char[] value = text;

            // Skip to '?>'
            while (text[0] != '?' || text[1] != '>')
            {
                if (text == null)
                    throw new XmlParsingException("unexpected end of data", text);
                text = text[1 .. $ ];
            }

            // Set pi value (verbatim, no entity expansion or whitespace normalization)
            pi.m_value = cast(string)value[ 0 .. value.length - text.length ].dup;

            // Place zero terminator after name and value
            // no need

            text = text[2 .. $ ];                          // Skip '?>'
            return pi;
        }
        else
        {
            // Skip to '?>'
            while (text[0] != '?' || text[1] != '>')
            {
                if (text[0] == '\0')
                    throw new XmlParsingException("unexpected end of data", text);
                text = text[1 .. $ ];
            }
            text = text[2 .. $ ];    // Skip '?>'
            return null;
        }
    }

    private Element parseComment(int Flags)(ref char[] text)
    {
        // If parsing of comments is disabled
        if (!(Flags & parse_comment_nodes))
        {
            // Skip until end of comment
            while (text[0] != '-' || text[1] != '-' || text[2] != '>')
            {
                if (!text[0]) throw new XmlParsingException("unexpected end of data", text);
                text = text[1 .. $];
            }
            text = text [3 .. $];     // Skip '-->'
            return null;      // Do not produce comment node
        }

        // Remember value start

        static if (Flags != 0)
        {
            string value = text;

            // Skip until end of comment
            while (text[0] != '-' || text[1] != '-' || text[2] != '>')
            {
                if (!text[0]) throw new XmlParsingException("unexpected end of data", text);
                text= text[1 .. $];
            }

            // Create comment node
            Element comment = new Element(NodeType.Comment);
            comment.m_value = cast(string)value[0 .. value.length - text.length].dup;

            // Place zero terminator after comment value
            // no need

            text = text[3 .. $ ];     // Skip '-->'
            return comment;
        }
    }

    // Parse DOCTYPE

    private Element parseDoctype(int Flags)(ref char[] text)
    {
        // Remember value start
        char[] value = text;

        // Skip to >
        while (text[0] != '>')
        {
            // Determine character type
            switch (text[0])
            {

            // If '[' encountered, scan for matching ending ']' using naive algorithm with depth
            // This works for all W3C test files except for 2 most wicked
            case ('['):
            {
                text = text[1 .. $ ];     // Skip '['
                int depth = 1;
                while (depth > 0)
                {
                    switch (text[0])
                    {
                        case '[': ++depth; break;
                        case ']': --depth; break;
                        default : throw new XmlParsingException("unexpected end of data", text);
                    }
                    text = text[1 .. $];
                }
                break;
            }

            // Error on end of text
            case '\0':
                throw new XmlParsingException("unexpected end of data", text);

            // Other character, skip it
            default:
                text = text[1 .. $ ];

            }
        }

        // If DOCTYPE nodes enabled
        if (Flags & parse_doctype_node)
        {
            // Create a new doctype node
            Element doctype = new Element(NodeType.DocumentType);
            doctype.m_value = cast(string)value[ 0 .. value.length - text.length].dup;

            // Place zero terminator after value
            // no need

            text = text[1 .. $ ];      // skip '>'
            return doctype;
        }
        else
        {
            text = text[1 .. $ ];      // skip '>'
            return null;
        }
    }

    void toFile(string fileName, bool isIndented = true) {
        import std.stdio;
        auto file = File(fileName, "w");
        scope(exit) {
            file.close();
        }
        auto textWriter = file.lockingTextWriter;
        if(isIndented) {
            auto writer = buildWriter(textWriter, PrettyPrinters.Indenter());
            writer.write(this);
        } else {
            auto writer = buildWriter(textWriter, PrettyPrinters.Minimalizer());
            writer.write(this);
        }
    }

    override string toString() {
        auto appender = Appender!string();
        auto writer = buildWriter(appender, PrettyPrinters.Minimalizer());
        writer.write(this);

        import hunt.logging.ConsoleLogger;
        return appender.data();
    }

    string toBeautifulString() {
        auto appender = Appender!string();
        auto writer = buildWriter(appender, PrettyPrinters.Indenter());
        writer.write(this);
        return appender.data();
    }
}