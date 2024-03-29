module hunt.xml.DocumentParser;

import hunt.xml.Attribute;
import hunt.xml.Common;
import hunt.xml.Document;
import hunt.xml.Element;
import hunt.xml.Node;
import hunt.xml.Internal;

import hunt.logging.ConsoleLogger;

/** 
 * 
 */
class DocumentParser {

    /** 
     * 
     * Params:
     *   stext = 
     *   null = 
     * Returns: 
     */
    static Document parse(ParsingFlags Flags = ParsingFlags.Default)(string stext , Document parent = null)
    {
        Document document = new Document();
        // document.removeAllNodes();
        // document.removeAllAttributes();
        document.setParent(parent ? parent.firstNode() : null);
        char[] text = cast(char[])stext.dup;

        parseBom(text);

        size_t index = 0;
        size_t length = text.length;
        while(1)
        {
            skip!(WhitespacePred)(text); 
            if(text.length == 0)
                break;
            if(text[index] =='<')
            {
                ++index;
                text = text[index .. $];
                Element  node = parseNode!(Flags)(text);
                if(node !is null)
                {
                    document.appendNode(node);
                    if(Flags & (ParsingFlags.OpenOnly | ParsingFlags.ParseOne))
                    {
                        if(node.getType()  == NodeType.Comment)
                            break;
                    }
                }
                index=0;
            }
            else
                throw new XmlParsingException("expected <", text);
        }

        if(!document.firstNode())
            throw new XmlParsingException("no root element", text[index .. $ ]);

        return document;
    }

    static private Element parseNode(int Flags)(ref char[] text)
    {
        switch(text[0])
        {
            // <...
            default:
                return parseElement!Flags(text);

            // <?...
            case '?':
                text = text[1 .. $ ];
                if(((text[0] == 'x' ) || (text[0] == 'X')) &&
                ((text[1] == 'm' ) || (text[1] == 'M')) &&
                ((text[2] == 'l' ) || (text[2] == 'L')) &&
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

    static private Element parseCdata(int Flags)(ref char[] text)
    {
        // If CDATA is disabled
        if (Flags & ParsingFlags.DataNodes)
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
        cdata.setText = cast(string)value[ 0 .. value.length - text.length].dup;

        // Place zero terminator after value

        text = text[3 .. $ ];      // Skip ]]>
        return cdata;
    }

    static private char parseAndAppendData(int Flags)(Element node, ref char []text, char[] contents_start)
    {
        // Backup to contents start if whitespace trimming is disabled
        if (!(Flags & ParsingFlags.TrimWhitespace))
            text = contents_start;

        // Skip until end of data
        char [] value = text;
        char []end;
        if (Flags & ParsingFlags.NormalizeWhitespace)
            end = skipAndExpandCharacterRefs!(TextPred, TextPureWithWsPred, Flags)(text);
        else
            end = skipAndExpandCharacterRefs!(TextPred, TextPureNoWsPred, Flags)(text);

        // Trim trailing whitespace if flag is set; leading was already trimmed by whitespace skip after >
        if (Flags & ParsingFlags.TrimWhitespace)
        {
            // FIXME: Needing refactor or cleanup -@zhangxueping at 2021-04-01T19:53:47+08:00
            // 
            if (Flags & ParsingFlags.NormalizeWhitespace)
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
        if (!(Flags & ParsingFlags.DataNodes))
        {
            Element data = new Element(NodeType.Text);
            data.setText = cast(string)value[0 .. value.length - end.length].dup;
            node.appendNode(data);
        }

        // Add data to parent node if no data exists yet
        if (!(Flags & ParsingFlags.EelementValues))
            if (node.getText.length == 0)
                node.setText = cast(string)value[0 ..value.length - end.length];

        // Place zero terminator after value
        if (!(Flags & ParsingFlags.StringTerminators))
        {
            ubyte ch = text[0];
            end[0] ='\0';
            return ch;      // Return character that ends data; this is required because zero terminator overwritten it
        }
        else
        // Return character that ends data
        return text[0];
    }

    static private Element parseElement(int Flags)(ref char[] text)
    {
        Element element = new Element();
        char[] prefix = text;
        //skip ElementNamePred
        skip!(ElementNamePred)(text);
        if(text == prefix)
            throw new XmlParsingException("expected element name or prefix", text);
        if(text.length >0 && text[0] == ':')
        {
            element.namespacePrefix = prefix[0 .. prefix.length - text.length].dup;
            text = text[1 .. $ ];
            char[] name = text;
            //skip NodeNamePred
            skip!(NodeNamePred)(text);
            if(text == name)
                throw new XmlParsingException("expected element local name", text);
            element.setName = name[0 .. name.length - text.length].dup;
        }
        else{
            element.setName = prefix[ 0 .. prefix.length - text.length].dup;            
        }

        //skip WhitespacePred
        skip!(WhitespacePred)(text);
        parseNodeAttributes!(Flags)(text , element);
        if(text.length > 0 && text[0] == '>')
        {
            text = text[1 .. $];
            char[] contents = text;
            char[] contents_end = null;
            if(!(Flags & ParsingFlags.OpenOnly))
            {    
                contents_end = parseNodeContents!(Flags)(text , element);
            }
            if(contents_end.length != contents.length )
            {
                element.contents = cast(string)contents[0 .. contents.length - contents_end.length].dup;
            }
        }
        else if(text.length > 0 && text[0] == '/')
        {
            text = text[1 .. $ ];
            if(text[0] != '>')
                throw new XmlParsingException("expected >", text);

            text = text[1 .. $ ];

            if(Flags & ParsingFlags.OpenOnly)
                throw new XmlParsingException("open_only, but closed", text);
        }
        else 
            throw new XmlParsingException("expected >", text);
        // Place zero terminator after name 
        // no need.
        return element;
    }

    static private char[] parseNodeContents(int Flags)(ref char[] text , Element node)
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
                    if(Flags & ParsingFlags.ValidateClosingTags)
                    {
                        string closing_name = cast(string)text.dup;
                        skip!(NodeNamePred)(text);
                        if(closing_name == node.getName)
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
                    if(Flags & ParsingFlags.OpenOnly)
                        throw new XmlParsingException("Unclosed element actually closed.", text);

                    return retval;
                }
                else
                {
                    text = text[1 .. $ ];
                    if(Element child = parseNode!(Flags & ~ParsingFlags.OpenOnly)(text))
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

    static private void parseNodeAttributes(int Flags)(ref char[] text , Element node)
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
            attribute.setName = cast(string)name[0 .. name.length - text.length].dup;

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
            const int AttFlags = Flags & ~ParsingFlags.NormalizeWhitespace;

            if(quote == '\'')
                end = skipAndExpandCharacterRefs!(AttributeValuePred!'\'' , AttributeValuePurePred!('\'') , AttFlags)(text);
            else
                end = skipAndExpandCharacterRefs!(AttributeValuePred!('"') , AttributeValuePurePred!('"') , AttFlags)(text);

            attribute.setValue = cast(string)value[0 .. value.length - end.length].dup;

            if(text.length > 0 && text[0] != quote)
                throw new XmlParsingException("expected ' or \"", text);

            text = text[1 .. $ ];

            skip!(WhitespacePred)(text);
        }
    }    


    static private void parseBom(ref char[] text)
    {
        if(text[0] == 0xEF 
        && text[1] == 0xBB 
        && text[2] == 0xBF)
        {
            text = text[3 .. $ ];
        }
    }

    static private Element parseXmlDeclaration(int Flags)(ref char[] text)
    {
        static if (Flags & ParsingFlags.DeclarationNode) {
            // Create declaration
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
        } else {
            // If parsing of declaration is disabled
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
    }

    static private Element parsePI(int Flags)(ref char[] text)
    {
        // If creation of PI nodes is enabled
        if (Flags & ParsingFlags.PiNodes)
        {
            // Create pi node
            Element pi = new Element(NodeType.ProcessingInstruction);

            // Extract PI target name
            char[] name = text;
            skip!NodeNamePred(text);
            if (text == name) 
                throw new XmlParsingException("expected PI target", text);
            pi.setName = cast(string)name[0 .. name.length - text.length].dup;

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
            pi.setText = cast(string)value[ 0 .. value.length - text.length ].dup;

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

    static private Element parseComment(int Flags)(ref char[] text)
    {
        static if (Flags & ParsingFlags.CommentNodes) {
            // Remember value start
            auto value = text;

            // Skip until end of comment
            while (text[0] != '-' || text[1] != '-' || text[2] != '>')
            {
                if (!text[0]) throw new XmlParsingException("unexpected end of data", text);
                text= text[1 .. $];
            }

            // Create comment node
            Element comment = new Element(NodeType.Comment);
            comment.setText = cast(string)value[0 .. value.length - text.length].dup;

            // Place zero terminator after comment value
            // no need

            text = text[3 .. $ ];     // Skip '-->'
            return comment;
        } else { 
            // If parsing of comments is disabled
            // Skip until end of comment
            while (text[0] != '-' || text[1] != '-' || text[2] != '>')
            {
                if (!text[0]) throw new XmlParsingException("unexpected end of data", text);
                text = text[1 .. $];
            }
            text = text [3 .. $];     // Skip '-->'
            return null;      // Do not produce comment node
        }


    }

    // Parse DOCTYPE

    static private Element parseDoctype(int Flags)(ref char[] text)
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
        if (Flags & ParsingFlags.DoctypeNode)
        {
            // Create a new doctype node
            Element doctype = new Element(NodeType.DocumentType);
            doctype.setText = cast(string)value[ 0 .. value.length - text.length].dup;

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

}