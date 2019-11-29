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
    protected Attribute m_prev_attribute;
    protected Attribute m_next_attribute;
    protected string    m_xmlns;
    protected string    m_local_name;
    protected string m_value;

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

    /// Gets previous attribute, optionally matching attribute name.
    /// \param name Name of attribute to find, or 0 to return previous attribute regardless of its name; this string doesn't have to be zero-terminated if name_size is non-zero
    /// \param name_size Size of name, in characters, or 0 to have size calculated automatically from string
    /// \param case_sensitive Should name comparison be case-sensitive; non case-sensitive comparison works properly only for ASCII characters
    /// \return Pointer to found attribute, or 0 if not found.

    Attribute previousAttribute(string name = null, bool caseSensitive = true)
    {
        if (name.length > 0) {
            if(caseSensitive) {
                for (Attribute attribute = m_prev_attribute; attribute; attribute = attribute.m_prev_attribute) {
                    if (attribute.getName() == name) return attribute;
                }
            } else {
                for (Attribute attribute = m_prev_attribute; attribute; attribute = attribute.m_prev_attribute) {
                    if (icmp(attribute.getName(), name) == 0) return attribute;
                }
            }
            return null;
        } else {
            return m_parent is null ? null : m_prev_attribute;
        }
    }

    void previousAttribute(Attribute attribute) {
        m_prev_attribute = attribute;
    }

    /** 
     * Gets next attribute, optionally matching attribute name.
     * 
     * Params:
     *   name = Name of attribute to find, or 0 to return next attribute regardless of its name; 
     * this string doesn't have to be zero-terminated if name_size is non-zero
     *   caseSensitive = Should name comparison be case-sensitive; non case-sensitive comparison 
     * works properly only for ASCII characters
     * 
     * Returns: 
     *   Pointer to found attribute, or 0 if not found.
     */
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

    void nextAttribute(Attribute attribute) {
        m_next_attribute = attribute;
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

    string localName() {
        if (m_local_name) return m_local_name;
        string p = this.getName();
        m_local_name = p;
        
        for (int i=0; i<p.length; ++i) {
            if( p[i] == ':') {
                m_local_name = p[i+1 .. $];
                break;
            }
        }

        return m_local_name;
    }
    
    void localName(string name) {
        m_local_name = name;
    }
}