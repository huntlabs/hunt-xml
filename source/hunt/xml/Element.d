module hunt.xml.Element;

import hunt.logging;

import hunt.xml.Attribute;
import hunt.xml.Common;
import hunt.xml.Document;
import hunt.xml.Node;

import std.format;
import std.string;

/** 
 * 
 */
class Element : Node {

    protected string m_prefix;
    protected string m_value;
    protected string m_xmlns;
    protected Element m_first_node;
    protected Element m_last_node;
    protected Attribute m_first_attribute;
    protected Attribute m_last_attribute;
    protected Element m_prev_sibling;
    protected Element m_next_sibling;
    protected string m_contents;

    this(NodeType type = NodeType.Element) {
        super(type);
    }

    this(string name, NodeType type = NodeType.Element) {
        super(name, type);
    }

    string xmlns()
    {
        if(m_xmlns.length > 0)
            return m_xmlns;
        char[] xmlns;
        lookupXmlns(xmlns , cast(char[])m_prefix);
        m_xmlns = cast(string)xmlns.dup;
        return m_xmlns;
    }

    Document document() 
    {
        Element node = cast(Element)(this);
        while (node.m_parent)
            node = node.m_parent;
        return node.m_type == NodeType.Document ? cast(Document)(node) : null;

    }

    package void lookupXmlns(ref char []xmlns,  char[]  prefix) 
    {
        char[] freeme;
        char[] attrname;
        int prefix_size = cast(int)prefix.length;
        if (prefix) {
            // Check if the prefix begins "xml".
            if (prefix_size >= 3
                && prefix[0] == ('x')
                && prefix[1] == ('m')
                && prefix[2] == ('l')) {
                if (prefix_size == 3) {
                    xmlns = cast(char[]) "http://www.w3.org/XML/1998/namespace";
                    return;
                } else if (prefix_size == 5
                            && prefix[3] == ('n')
                            && prefix[4] == ('s')) {
                    xmlns = cast(char[]) "http://www.w3.org/2000/xmlns/";
                    return;
                }
            }

            attrname.length = prefix_size + 6;
            freeme = attrname;
            string p1= "xmlns";
            for(int i = 0 ;i < p1.length ; i++)
                attrname[i] = p1[i];

            char [] p = prefix;
            attrname[p1.length] = ':';
            int index = cast(int)p1.length + 1;
            while (p.length > 0) {
                attrname[index++] = p[0];
                p = p[1 .. $];
                if ((freeme.length - attrname[index .. $].length ) >= (prefix_size + 6)) break;
            }
            attrname = freeme;
        } else {
            attrname.length = 5;
            freeme = attrname ;
            string p1="xmlns";
            for(int i = 0 ;i < p1.length ; i++)
                attrname[i] = p1[i];
            attrname = freeme;
        }

        for ( Element node = this;
                node;
                node = node.m_parent) {
            Attribute attr = node.firstAttribute(cast(string)attrname);
            if (attr !is null ) {
                xmlns = cast(char[])attr.getValue().dup;
                break;
            }
        }
        if (xmlns.length == 0) {
            if (prefix.length == 0) {
                xmlns = cast(char[])"nullstring".dup;
            }
        }

    }

	/**
	 * Returns the fully qualified name of this element. This will be the same
	 * as the value returned from {@link #getName}if this element has no
	 * namespace attached to this element or an expression of the form
	 * <pre>
	 * getNamespacePrefix() + &quot;:&quot; + getName()
	 * </pre>
	 * will be returned.
	 *
	 * @return the fully qualified name of the element.
	 */
	string namespacePrefix() {
        return m_prefix;
    }

    void namespacePrefix(string name) {
        m_prefix = name;
    }

    /**
	 * Returns the fully qualified name of this element. This will be the same
	 * as the value returned from {@link #getName}if this element has no
	 * namespace attached to this element or an expression of the form
	 * <pre>
	 * getNamespacePrefix() + &quot;:&quot; + getName()
	 * </pre>
	 * will be returned.
	 *
	 * @return the fully qualified name of the element.
	 */
	string getQualifiedName() {
        // TODO: Tasks pending completion -@zhangxueping at 2019-11-26T17:44:39+08:00
        // 
        if(m_prefix.empty())
            return getName();
        return m_prefix ~ "&quot;:&quot;" ~ getName();
    }


    /**
     * <p>
     * Returns the text of this node.
     * </p>
     * 
     * @return the text for this node.
     */
    string getText() {
        return m_value;
    }

    /**
     * <p>
     * Sets the text data of this node or this method will throw an
     * <code>UnsupportedOperationException</code> if it is read-only.
     * </p>
     * 
     * @param text
     *            is the new textual value of this node
     */
    void setText(string text) {
        m_value = text;
    }

    string contents() {
        return m_contents;
    }

    void contents(string text) {
        m_contents = text;
    }

    Element firstNode(string name = null , string xmlns = null , bool caseSensitive = true)
    {
        if(xmlns.length == 0 && name.length > 0)
        {
            xmlns = this.xmlns();
        }

        for(Element child = m_first_node ; child ; child = child.m_next_sibling)
        {
            if((!name || child.m_name == name) && (!xmlns || child.xmlns() == xmlns))
            {                
                return child;
            }
        }

        return null;
    }

    Element lastNode(string name = null , string xmlns = null , bool caseSensitive = true)
    {
        for(Element child = m_last_node ; child ; child = child.m_prev_sibling)
        {
            if((!name || child.m_name == name) && (!xmlns || child.xmlns() == xmlns))
                return child;
        }

        return null;
    }

    Element previousSibling(string name = null , string xmlns = null , bool caseSensitive = true)
    {
        assert(this.m_parent);     // Cannot query for siblings if node has no parent
        if (name.length == 0)
            return m_prev_sibling;

        if (xmlns.length == 0) {
            // No XMLNS asked for, but a name is present.
            // Assume "same XMLNS".
            xmlns = this.xmlns();
        }

        if(caseSensitive) {
            for (Element sibling = m_prev_sibling; sibling !is null; sibling = sibling.m_prev_sibling) {
                if ((sibling.getName() == name)
                    && (xmlns.length == 0 || (sibling.xmlns() == xmlns)))
                    return sibling;
            }
        } else {
            for (Element sibling = m_prev_sibling; sibling !is null; sibling = sibling.m_prev_sibling) {
                if ((icmp(sibling.getName(), name) == 0)
                    && (xmlns.length == 0 || icmp(sibling.xmlns(), xmlns) == 0))
                    return sibling;
            }
        }

        return null;
    }
    
    Element nextSibling(string name = null , string xmlns = null , bool caseSensitive = true) {
        if (name.length == 0)
            return m_next_sibling;

        if (xmlns.length == 0) {
            // No XMLNS asked for, but a name is present.
            // Assume "same XMLNS".
            xmlns = this.xmlns();
        }

        if(caseSensitive) {
            for (Element sibling = m_next_sibling; sibling !is null; sibling = sibling.m_next_sibling) {
                if ((sibling.getName() == name)
                    && (xmlns.length == 0 || (sibling.xmlns() == xmlns)))
                    return sibling;
            }
        } else {
            for (Element sibling = m_next_sibling; sibling !is null; sibling = sibling.m_next_sibling) {
                if ((icmp(sibling.getName(), name) == 0)
                    && (xmlns.length == 0 || icmp(sibling.xmlns(), xmlns) == 0))
                    return sibling;
            }
        }
        return null;
    }


    void prependNode(Element child)
    {
        if(firstNode())
        {
            child.m_next_sibling = m_first_node;
            m_first_node.m_prev_sibling = child;
        }
        else
        {
            child.m_next_sibling = null;
            m_last_node = child;
        }

        m_first_node = child;
        child.m_parent = this;
        child.m_prev_sibling = null;
    }

    void appendNode(Element child)
    {
        if(firstNode())
        {
            child.m_prev_sibling = m_last_node;
            m_last_node.m_next_sibling = child;
        }
        else
        {
            child.m_prev_sibling = null;
            m_first_node = child;
        }

        m_last_node = child;
        child.m_parent = this;
        child.m_next_sibling = null;
    }

    void insertNode(Element where , Element child)
    {
        if(where == m_first_node)
            prependNode(child);
        else if(where is null)
            appendNode(child);
        else
        {
            child.m_prev_sibling = where.m_prev_sibling;
            child.m_next_sibling = where;
            where.m_prev_sibling.m_next_sibling = child;
            where.m_prev_sibling = child;
            child.m_parent = this;
        }
    }

    void removeFirstNode()
    {
        Element child = m_first_node;
        m_first_node = child.m_next_sibling;
        if(child.m_next_sibling)
            child.m_next_sibling.m_prev_sibling = null;
        else
            m_last_node = null;
        child.m_parent = null;
    }

    void removeLastNode()
    {
        Element child = m_last_node;
        if(child.m_prev_sibling)
        {
            m_last_node = child.m_prev_sibling;
            child.m_prev_sibling.m_next_sibling = null;
        }
        else
        {
            m_first_node = null;
        }

        child.m_parent = null;
    }

    void removeNode(Element where)
    {
        if(where == m_first_node)
            removeFirstNode();
        else if(where == m_last_node)
            removeLastNode();
        else
        {
            where.m_prev_sibling.m_next_sibling = where.m_next_sibling;
            where.m_next_sibling.m_prev_sibling = where.m_prev_sibling;
            where.m_parent = null;
        }
    }

    void removeAllNodes()
    {
        for( Element node = firstNode(); node; node = node.m_next_sibling)
            node.m_parent = null;

        m_first_node = null;
    }

    Attribute firstAttribute(string name = null , bool caseSensitive = true)
    {
        if(name)
        {
            for(Attribute attribute = m_first_attribute ; attribute ; attribute = attribute.nextAttribute())
            {

                if(attribute.m_name == name)
                {    
                    return attribute;
                }
            }

            return null;
        }
        else
        {
            return m_first_attribute;
        }
    }

    Attribute lastAttribute(string name = null , bool caseSensitive = true)
    {
        if(name)
        {
            for(Attribute attribute = m_last_attribute ; attribute ; attribute = attribute.previousAttribute())
            {
                if(attribute.m_name == name)
                    return attribute;
            }

            return null;
        }
        else
        {
            return m_last_attribute;
        }
    }

    void prependAttribute(Attribute attribute)
    {
        if(firstAttribute())
        {
            attribute.nextAttribute = m_first_attribute;
            m_first_attribute.previousAttribute = attribute;
        }
        else
        {
            attribute.nextAttribute = cast(Attribute)null;
            m_last_attribute = attribute;
        }
        m_first_attribute = attribute;
        attribute.m_parent = this;
        attribute.previousAttribute = cast(Attribute)null;
    }

    void appendAttribute(Attribute attribute)
    {
        if(firstAttribute())
        {
            attribute.previousAttribute = m_last_attribute;
            m_last_attribute.nextAttribute = attribute;
        }
        else
        {
            attribute.previousAttribute = cast(Attribute)null;
            m_first_attribute = attribute;
        }

        m_last_attribute = attribute;
        attribute.m_parent = this;
        attribute.nextAttribute = cast(Attribute)null;
    }

    void insertAttribute(Attribute where , Attribute attribute)
    {
        if(where == m_first_attribute)
            prependAttribute(attribute);
        else if(where is null)
            appendAttribute(attribute);
        else
        {
            attribute.previousAttribute = where.previousAttribute();
            attribute.nextAttribute = where;
            where.previousAttribute().nextAttribute = attribute;
            where.previousAttribute = attribute;
            attribute.m_parent = this;
        }
    }

    void removeFirstAttribute()
    {
        Attribute attribute = m_first_attribute;
        if(attribute.nextAttribute())
        {
            attribute.nextAttribute().previousAttribute = cast(Attribute)null;
        }
        else
        {
            m_last_attribute = null;
        }

        attribute.m_parent = null;
        m_first_attribute = attribute.nextAttribute();
    }

    void removeLastAttribute()
    {
        Attribute attribute = m_last_attribute;
        if(attribute.previousAttribute())
        {
            attribute.previousAttribute().nextAttribute = cast(Attribute)null;
            m_last_attribute = attribute.previousAttribute();
        }
        else
            m_first_attribute = null;

        attribute.m_parent = null;
    }

    void removeAttribute(Attribute where)
    {
        if(where == m_first_attribute)
            removeFirstAttribute();
        else if(where == m_last_attribute)
            removeLastAttribute();
        else
        {
            where.previousAttribute().nextAttribute = where.nextAttribute();
            where.nextAttribute().previousAttribute = where.previousAttribute();
            where.m_parent = null;
        }
    }

    void removeAllAttributes()
    {
        for(Attribute attribute = firstAttribute() ; attribute ; attribute = attribute.nextAttribute())
        {
            attribute.m_parent = null;
        }
        m_first_attribute = null;
    }

    bool validate()
    {
        if(this.xmlns() == null)
        {    
            debug(HUNT_DEBUG) trace("Element XMLNS unbound");
            return false;
        }
        for(Element child = firstNode(); child ; child = child.m_next_sibling)
        {
            if(!child.validate())
                return false;
        }
        for(Attribute attribute = firstAttribute() ; attribute ; attribute = attribute.nextAttribute())
        {
            if(attribute.xmlns() == null)
            {    
                debug(HUNT_DEBUG) trace("Attribute XMLNS unbound");
                return false;
            }
            for(Attribute otherattr = firstAttribute() ; otherattr != attribute; otherattr = otherattr.nextAttribute())
            {    
                if(attribute.m_name == otherattr.m_name)
                {    
                    debug(HUNT_DEBUG) trace("Attribute doubled");
                    return false;
                }
                if(attribute.xmlns() == otherattr.xmlns() && attribute.localName() == otherattr.localName())
                {
                    debug(HUNT_DEBUG) trace("Attribute XMLNS doubled");
                    return false;
                }
            }

        }
        return true;
    }

    override string toString() {
        return format("name: %s, text: %s", m_name, m_value);
    }    
}
