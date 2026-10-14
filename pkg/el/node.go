// Package el builds HTML as plain data and renders it with a Renderer.
//
// Nodes carry no rendering logic: they are values that can be compared with
// == or reflect.DeepEqual. Element and attribute names are typed constants
// (Tag and AttrName) so that passing one where the other is expected fails
// to compile. See docs/ja/design.md for the design principles.
package el

// Node is a marker interface implemented by every node type in this package.
type Node interface {
	node()
}

// Tag is an element name such as "div".
type Tag string

// AttrName is an attribute name such as "class".
type AttrName string

// TextNode is text content. It is escaped when rendered as HTML.
type TextNode string

// RawNode is trusted markup written as is. Never put user input in it.
type RawNode string

// ElementNode is an element. AttrNode and BoolAttrNode children go into the
// start tag; every other child becomes content.
type ElementNode struct {
	Name     Tag
	Children []Node
}

// AttrNode is an attribute with a value, such as class="x".
type AttrNode struct {
	Name  AttrName
	Value string
}

// BoolAttrNode is an attribute without a value, such as hidden.
type BoolAttrNode AttrName

func (TextNode) node()     {}
func (RawNode) node()      {}
func (ElementNode) node()  {}
func (AttrNode) node()     {}
func (BoolAttrNode) node() {}

// El returns an element with the given children.
func El(name Tag, children ...Node) ElementNode {
	return ElementNode{Name: name, Children: children}
}

// Attr returns an attribute with a value.
func Attr(key AttrName, val string) AttrNode {
	return AttrNode{Name: key, Value: val}
}

// Text returns a text node. The text is escaped when rendered as HTML.
func Text(s string) TextNode {
	return TextNode(s)
}

// Raw returns a node written without escaping. Use it only for trusted,
// static strings such as embedded CSS.
func Raw(s string) RawNode {
	return RawNode(s)
}
