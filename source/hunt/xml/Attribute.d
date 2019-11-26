module hunt.xml.Attribute;

import hunt.xml.Common;
import hunt.xml.Document;
import hunt.xml.Element;
import hunt.xml.Node;


class Attribute : Node
{
    Attribute m_prev_attribute;
    Attribute m_next_attribute;
    string    m_xmlns;
    string    m_local_name;

    this() {
        
        m_type = NodeType.Attribute;
    }

    Document document() 
    {
        if (Element node = m_parent)
        {
            while (node.m_parent)
                node = node.m_parent;
            return node.m_type == NodeType.Document ? cast(Document)(node) : null;
        }
        else
            return null;
    }

    string xmlns() 
    {
        if (m_xmlns) return m_xmlns;
        char[] p;
        char[] name = cast(char[])m_name.dup;
        for (p = name; p.length > 0 && p[0] != ':'; p=p[1..$])
        {    
            if ((m_name.length - p.length) >= m_name.length) 
                break;
        }
        if (p.length == 0 || ((m_name.length - p.length) >= m_name.length)) {
            m_xmlns = "nullstring";
            return m_xmlns;
        }
        Element  element = m_parent;
        if (element) 
        {
            char []xmlns = cast(char[])m_xmlns;
            element.lookupXmlns(xmlns, name[0 .. m_name.length - p.length]);
            m_xmlns = cast(string)xmlns.dup;
        }
        return m_xmlns;
    }
}