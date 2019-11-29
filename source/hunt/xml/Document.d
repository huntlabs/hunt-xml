module hunt.xml.Document;

import hunt.xml.Attribute;
import hunt.xml.Common;
import hunt.xml.Element;
import hunt.xml.Node;
import hunt.xml.Internal;
import hunt.xml.DocumentParser;

import hunt.xml.Writer;

import std.array : Appender;

import hunt.logging.ConsoleLogger;

/** 
 * 
 */
class Document : Element {
    this() {
        m_type = NodeType.Document;
    }

    static Document parse(ParsingFlags Flags = ParsingFlags.Full)(string text) {
        return DocumentParser.parse!(Flags)(text);
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

    string toPrettyString() {
        auto appender = Appender!string();
        auto writer = buildWriter(appender, PrettyPrinters.Indenter());
        writer.write(this);
        return appender.data();
    }

    override string toString() {
        auto appender = Appender!string();
        auto writer = buildWriter(appender, PrettyPrinters.Minimalizer());
        writer.write(this);
        return appender.data();
    }
}