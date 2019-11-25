# rapidxml
A XML Parsing library for D Programming Language. Ported from C++ [rapidxml](http://rapidxml.sourceforge.net).

# Example

```D

import rapidxml;

import stdio;

void main()
{
    auto doc = new Document;

    string xml = "<single-element/>";

    doc.parse(xml);

    auto node = doc.firstNode();

    writeln(node.getName());

    doc.validate();
}
