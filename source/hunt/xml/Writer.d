module hunt.xml.Writer;

import hunt.xml.Attribute;
import hunt.xml.Common;
import hunt.xml.Document;
import hunt.xml.Element;
import hunt.xml.Node;

import hunt.logging.ConsoleLogger;

private string ifCompiles(string code) {
    return "static if (__traits(compiles, " ~ code ~ ")) " ~ code ~ ";\n";
}

private string ifCompilesElse(string code, string fallback) {
    return "static if (__traits(compiles, " ~ code ~ ")) " ~ code ~ "; else " ~ fallback ~ ";\n";
}

private string ifAnyCompiles(string code, string[] codes...) {
    if (codes.length == 0)
        return "static if (__traits(compiles, " ~ code ~ ")) " ~ code ~ ";";
    else
        return "static if (__traits(compiles, " ~ code ~ ")) " ~ code ~ "; else "
            ~ ifAnyCompiles(codes[0], codes[1 .. $]);
}

import std.typecons : tuple;

private auto xmlDeclarationAttributes(Args...)(Args args) {
    static assert(Args.length <= 3, "Too many arguments for xml declaration");

    // version specification
    static if (is(Args[0] == int)) {
        assert(args[0] == 10 || args[0] == 11, "Invalid xml version specified");
        string versionString = args[0] == 10 ? "1.0" : "1.1";
        auto args1 = args[1 .. $];
    } else static if (is(Args[0] == string)) {
        string versionString = args[0];
        auto args1 = args[1 .. $];
    } else {
        string versionString = [];
        auto args1 = args;
    }

    // encoding specification
    static if (is(typeof(args1[0]) == string)) {
        auto encodingString = args1[0];
        auto args2 = args1[1 .. $];
    } else {
        string encodingString = [];
        auto args2 = args1;
    }

    // standalone specification
    static if (is(typeof(args2[0]) == bool)) {
        string standaloneString = args2[0] ? "yes" : "no";
        auto args3 = args2[1 .. $];
    } else {
        string standaloneString = [];
        auto args3 = args2;
    }

    // catch other erroneous parameters
    static assert(typeof(args3).length == 0,
            "Unrecognized attribute type for xml declaration: " ~ typeof(args3[0]).stringof);

    return tuple(versionString, encodingString, standaloneString);
}

/++
+   A collection of ready-to-use pretty-printers
+/
struct PrettyPrinters {
    /++
    +   The minimal pretty-printer. It just guarantees that the input satisfies
    +   the xml grammar.
    +/
    struct Minimalizer {
        // minimum requirements needed for correctness
        enum string beforeAttributeName = " ";
        enum string betweenPITargetData = " ";
    }
    /++
    +   A pretty-printer that indents the nodes with a tabulation character
    +   `'\t'` per level of nesting.
    +/
    struct Indenter {
        // inherit minimum requirements
        Minimalizer minimalizer;
        alias minimalizer this;

        enum string afterNode = "\n";
        enum string attributeDelimiter = "'";

        uint indentation;
        enum string tab = "\t";
        void decreaseLevel() {
            indentation--;
        }

        void increaseLevel() {
            indentation++;
        }

        void beforeNode(Out)(ref Out output) {
            foreach (i; 0 .. indentation)
                output.put(tab);
        }
    }
}

auto buildWriter(OutRange, PrettyPrinter)(ref OutRange output, PrettyPrinter pretty) {
    return Writer!(OutRange, PrettyPrinter)(output, pretty);
}

struct Writer(alias OutRange, alias PrettyPrinter = PrettyPrinters.Minimalizer) {
    private PrettyPrinter prettyPrinter;
    private OutRange output;

    bool startingTag = false, insideDTD = false;

    this(ref OutRange output, PrettyPrinter pretty) {
        this.output = output;
        prettyPrinter = pretty;
    }

    private template expand(string methodName) {
        import std.meta : AliasSeq;

        alias expand = AliasSeq!("prettyPrinter." ~ methodName ~ "(output)",
                "output.put(prettyPrinter." ~ methodName ~ ")");
    }

    private template formatAttribute(string attribute) {
        import std.meta : AliasSeq;

        alias formatAttribute = AliasSeq!("prettyPrinter.formatAttribute(output, " ~ attribute ~ ")",
                "output.put(prettyPrinter.formatAttribute(" ~ attribute ~ "))",
                "defaultFormatAttribute(" ~ attribute ~ ", prettyPrinter.attributeDelimiter)",
                "defaultFormatAttribute(" ~ attribute ~ ")");
    }

    private void defaultFormatAttribute(string attribute, string delimiter = "'") {
        // TODO: delimiter escaping
        output.put(delimiter);
        output.put(attribute);
        output.put(delimiter);
    }

    /++
    +   Outputs an XML declaration.
    +
    +   Its arguments must be an `int` specifying the version
    +   number (`10` or `11`), a string specifying the encoding (no check is performed on
    +   this parameter) and a `bool` specifying the standalone property of the document.
    +   Any argument can be skipped, but the specified arguments must respect the stated
    +   ordering (which is also the ordering required by the XML specification).
    +/
    void writeXMLDeclaration(Args...)(Args args) {
        auto attrs = xmlDeclarationAttributes(args);

        output.put("<?xml");

        if (attrs[0]) {
            mixin(ifAnyCompiles(expand!"beforeAttributeName"));
            output.put("version");
            mixin(ifAnyCompiles(expand!"afterAttributeName"));
            output.put("=");
            mixin(ifAnyCompiles(expand!"beforeAttributeValue"));
            mixin(ifAnyCompiles(formatAttribute!"attrs[0]"));
        }
        if (attrs[1]) {
            mixin(ifAnyCompiles(expand!"beforeAttributeName"));
            output.put("encoding");
            mixin(ifAnyCompiles(expand!"afterAttributeName"));
            output.put("=");
            mixin(ifAnyCompiles(expand!"beforeAttributeValue"));
            mixin(ifAnyCompiles(formatAttribute!"attrs[1]"));
        }
        if (attrs[2]) {
            mixin(ifAnyCompiles(expand!"beforeAttributeName"));
            output.put("standalone");
            mixin(ifAnyCompiles(expand!"afterAttributeName"));
            output.put("=");
            mixin(ifAnyCompiles(expand!"beforeAttributeValue"));
            mixin(ifAnyCompiles(formatAttribute!"attrs[2]"));
        }

        mixin(ifAnyCompiles(expand!"beforePIEnd"));
        output.put("?>");
        mixin(ifAnyCompiles(expand!"afterNode"));
    }

    void writeXMLDeclaration(string version_, string encoding, string standalone) {
        output.put("<?xml");

        if (version_) {
            mixin(ifAnyCompiles(expand!"beforeAttributeName"));
            output.put("version");
            mixin(ifAnyCompiles(expand!"afterAttributeName"));
            output.put("=");
            mixin(ifAnyCompiles(expand!"beforeAttributeValue"));
            mixin(ifAnyCompiles(formatAttribute!"version_"));
        }
        if (encoding) {
            mixin(ifAnyCompiles(expand!"beforeAttributeName"));
            output.put("encoding");
            mixin(ifAnyCompiles(expand!"afterAttributeName"));
            output.put("=");
            mixin(ifAnyCompiles(expand!"beforeAttributeValue"));
            mixin(ifAnyCompiles(formatAttribute!"encoding"));
        }
        if (standalone) {
            mixin(ifAnyCompiles(expand!"beforeAttributeName"));
            output.put("standalone");
            mixin(ifAnyCompiles(expand!"afterAttributeName"));
            output.put("=");
            mixin(ifAnyCompiles(expand!"beforeAttributeValue"));
            mixin(ifAnyCompiles(formatAttribute!"standalone"));
        }

        output.put("?>");
        mixin(ifAnyCompiles(expand!"afterNode"));
    }

    /++
    +   Outputs a comment with the given content.
    +/
    void writeComment(string comment) {
        closeOpenThings;

        mixin(ifAnyCompiles(expand!"beforeNode"));
        output.put("<!--");
        mixin(ifAnyCompiles(expand!"afterCommentStart"));

        mixin(ifCompilesElse("prettyPrinter.formatComment(output, comment)", "output.put(comment)"));

        mixin(ifAnyCompiles(expand!"beforeCommentEnd"));
        output.put("-->");
        mixin(ifAnyCompiles(expand!"afterNode"));
    }
    /++
    +   Outputs a text node with the given content.
    +/
    void writeText(string text) {
        //assert(!insideDTD);
        closeOpenThingsSimplely();
        mixin(ifCompilesElse("prettyPrinter.formatText(output, text)", "output.put(text)"));
    }


    /++
    +   Outputs a CDATA section with the given content.
    +/
    void writeCDATA(string cdata) {
        assert(!insideDTD);
        closeOpenThings;

        mixin(ifAnyCompiles(expand!"beforeNode"));
        output.put("<![CDATA[");
        output.put(cdata);
        output.put("]]>");
        mixin(ifAnyCompiles(expand!"afterNode"));
    }
    /++
    +   Outputs a processing instruction with the given target and data.
    +/
    void writeProcessingInstruction(string target, string data) {
        closeOpenThings;

        mixin(ifAnyCompiles(expand!"beforeNode"));
        output.put("<?");
        output.put(target);
        mixin(ifAnyCompiles(expand!"betweenPITargetData"));
        output.put(data);

        mixin(ifAnyCompiles(expand!"beforePIEnd"));
        output.put("?>");
        mixin(ifAnyCompiles(expand!"afterNode"));
    }

    private void closeOpenThings() {
        if (startingTag) {
            mixin(ifAnyCompiles(expand!"beforeElementEnd"));
            output.put(">");
            mixin(ifAnyCompiles(expand!"afterNode"));
            startingTag = false;
            mixin(ifCompiles("prettyPrinter.increaseLevel"));
        }
    }
    
    private void closeOpenThingsSimplely() {
        if (startingTag) {
            output.put(">");
            startingTag = false;
        }
    }

    void startElement(string tagName) {
        closeOpenThings();

        mixin(ifAnyCompiles(expand!"beforeNode"));
        output.put("<");
        output.put(tagName);
        startingTag = true;
    }

    void closeElement(string tagName) {
        bool selfClose;
        mixin(ifCompilesElse("selfClose = prettyPrinter.selfClosingElements", "selfClose = true"));

        if (selfClose && startingTag) {
            mixin(ifAnyCompiles(expand!"beforeElementEnd"));
            output.put("/>");
            startingTag = false;
        } else {
            closeOpenThings;

            mixin(ifCompiles("prettyPrinter.decreaseLevel"));
            mixin(ifAnyCompiles(expand!"beforeNode"));
            output.put("</");
            output.put(tagName);
            mixin(ifAnyCompiles(expand!"beforeElementEnd"));
            output.put(">");
        }
        mixin(ifAnyCompiles(expand!"afterNode"));
    }

    void closeElementWithTextNode(string tagName) {
        bool selfClose;
        mixin(ifCompilesElse("selfClose = prettyPrinter.selfClosingElements", "selfClose = true"));

        if (selfClose && startingTag) {
            mixin(ifAnyCompiles(expand!"beforeElementEnd"));
            output.put("/>");
            startingTag = false;
        } else {
            closeOpenThings;

            // mixin(ifCompiles("prettyPrinter.decreaseLevel"));
            // mixin(ifAnyCompiles(expand!"beforeNode"));
            output.put("</");
            output.put(tagName);
            mixin(ifAnyCompiles(expand!"beforeElementEnd"));
            output.put(">");
        }
        mixin(ifAnyCompiles(expand!"afterNode"));
    }    

    void writeAttribute(string name, string value) {
        assert(startingTag, "Cannot write attribute outside element start");

        mixin(ifAnyCompiles(expand!"beforeAttributeName"));
        output.put(name);
        mixin(ifAnyCompiles(expand!"afterAttributeName"));
        output.put("=");
        mixin(ifAnyCompiles(expand!"beforeAttributeValue"));
        mixin(ifAnyCompiles(formatAttribute!"value"));
    }

    void startDoctype(string content) {
        assert(!insideDTD && !startingTag);

        mixin(ifAnyCompiles(expand!"beforeNode"));
        output.put("<!DOCTYPE");
        output.put(content);
        mixin(ifAnyCompiles(expand!"afterDoctypeId"));
        output.put("[");
        insideDTD = true;
        mixin(ifAnyCompiles(expand!"afterNode"));
        mixin(ifCompiles("prettyPrinter.increaseLevel"));
    }

    void closeDoctype() {
        assert(insideDTD);

        mixin(ifCompiles("prettyPrinter.decreaseLevel"));
        insideDTD = false;
        mixin(ifAnyCompiles(expand!"beforeDTDEnd"));
        output.put("]>");
        mixin(ifAnyCompiles(expand!"afterNode"));
    }

    void writeDeclaration(string decl, string content) {
        //assert(insideDTD);

        mixin(ifAnyCompiles(expand!"beforeNode"));
        output.put("<!");
        output.put(decl);
        output.put(content);
        output.put(">");
        mixin(ifAnyCompiles(expand!"afterNode"));
    }

    void write(Document doc) {
        tracef("name: %s, type: %s", doc.getName(), doc.getType());

        for (Element child = doc.firstNode(); child; child = child.nextSibling()) {
            infof("name: %s, value: %s, type: %s", child.getName(),
                    child.getText(), child.getType());
            writeNode(child);
        }

    }

    private void writeNode(Element node) {
        // Print proper node type
        switch (node.getType()) {
        case NodeType.Document:
            writeChildren(node);
            break;

        case NodeType.Element:
            writeElement(node);
            break;

        case NodeType.Text:
            // writeNodeText(node);
            writeText(node.getText());
            break;

        default:
            warningf("name: %s, type: %s", node.getName(), node.getType());
            break;
        }
    }

    /** 
     * Print children of the node
     * 
     * Params:
     *   node = 
     */
    private void writeChildren(Element node) {
        debug(HUNT_DEBUG) tracef("name: %s, type: %s", node.getName(), node.getType());
        for (Element child = node.firstNode(); child; child = child.nextSibling()) {
            writeNode(child);
        }
    }

    private void writeAttributes(Element element) {
        for (Attribute attribute = element.firstAttribute(); attribute !is null; attribute = attribute.nextAttribute()) {
            writeAttribute(attribute.getName(), attribute.getValue());
        }
    }

    private void writeElement(Element element) {
        Element child = element.firstNode();         
        debug(HUNT_DEBUG) tracef("name %s, type: %s, text: %s", element.getName(), element.getType(), element.getText());
        
        startElement(element.getQualifiedName());
        writeAttributes(element);

        if(child is null) {
            closeElement(element.getQualifiedName());
        } else if(child.getType() == NodeType.Text) {
            if(child !is null) {
                infof("value %s, type: %s", child.getText(), child.getType());
            }
            writeText(element.getText());
            closeElementWithTextNode(element.getQualifiedName());
        } else {
            debug(HUNT_DEBUG) infof("name %s, type: %s", child.getName(), child.getType());
            writeChildren(element);
            closeElement(element.getQualifiedName());
        }
    }
}
