/*
 * Hunt - A xml library for D programming language.
 *
 * Copyright (C) 2006, 2009 Marcin Kalicinski (For C++ Version 1.13)
 * Copyright (C) 2018-2019 HuntLabs ( For D Language Version)
 *
 * Website: https://www.huntlabs.net
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.xml.Node;

import hunt.xml.Element;

/**
 * <code>Node</code> defines the polymorphic behavior for all XML nodes in a
 * dom tree.
 *
 * A node can be output as its XML format, can be detached from its position in
 * a document and can have XPath expressions evaluated on itself.
 *
 * A node may optionally support the parent relationship and may be read only.
 *
 */
class Node {
    protected string m_name;
    protected string m_value;
    protected Element m_parent;

    /**
     * <p>
     * <code>getName</code> returns the name of this node. This is the XML
     * local name of the element, attribute, entity or processing instruction.
     * For CDATA and Text nodes this method will return null.
     * </p>
     * 
     * @return the XML name of this node
     */
    string getName() {
        return m_name;
    }

    /**
     * <p>
     * Sets the text data of this node or this method will throw an
     * <code>UnsupportedOperationException</code> if it is read-only.
     * </p>
     * 
     * @param name
     *            is the new name of this node
     */
    void setName(string name) {
        m_name = name;
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

    /**
     * <p>
     * <code>getParent</code> returns the parent <code>Element</code> if
     * this node supports the parent relationship or null if it is the root
     * element or does not support the parent relationship.
     * </p>
     * 
     * <p>
     * This method is an optional feature and may not be supported for all
     * <code>Node</code> implementations.
     * </p>
     * 
     * @return the parent of this node or null if it is the root of the tree or
     *         the parent relationship is not supported.
     */
    Element getParent() {
        return m_parent;
    }

}
