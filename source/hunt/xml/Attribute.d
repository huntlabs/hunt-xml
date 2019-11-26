module hunt.xml.Attribute;

import hunt.xml.Common;
import hunt.xml.Document;
import hunt.xml.Element;
import hunt.xml.Node;

import std.string;

/** 
 * 
 */
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

    Attribute nextAttribute(string name = null , bool caseSensitive = true) {
        if (name.length > 0)
        {
            if(caseSensitive) {
                for (Attribute attribute = m_next_attribute; attribute !is null; attribute = attribute.m_next_attribute) {
                    if (attribute.getName() == name)
                        return attribute;
                }
            } else {
                for (Attribute attribute = m_next_attribute; attribute !is null; attribute = attribute.m_next_attribute) {
                    if (icmp(attribute.getName(), name) == 0)
                        return attribute;
                }
            }
            return null;
        }
        else {
            return m_parent is null ? null : m_next_attribute;
        }
    }


	/**
	 * Returns the value of the attribute. This method returns the same value as
	 * the {@link Node#getText()}method.
	 *
	 * @return the value of the attribute
	 */
	string getValue() {
        return m_value;
    }

	/**
	 * Sets the value of this attribute or this method will throw an
	 * <code>UnsupportedOperationException</code> if it is read-only.
	 *
	 * @param value is the new value of this attribute
	 */
	void setValue(string value) {
        m_value = value;
    }
    
}