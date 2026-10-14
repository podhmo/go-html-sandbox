package el

// Element names. Add a line here to support a new element; for a one-off
// dynamic name, convert directly: Tag("my-widget").
//
// When an element and an attribute share a name, the element keeps the bare
// name and the attribute gets an Attr suffix (e.g. Title / TitleAttr).
const (
	A       Tag = "a"
	Article Tag = "article"
	Body    Tag = "body"
	Br      Tag = "br"
	Code    Tag = "code"
	Div     Tag = "div"
	Footer  Tag = "footer"
	H1      Tag = "h1"
	H2      Tag = "h2"
	H3      Tag = "h3"
	H4      Tag = "h4"
	Head    Tag = "head"
	Header  Tag = "header"
	Hgroup  Tag = "hgroup"
	Hr      Tag = "hr"
	HTML    Tag = "html"
	Img     Tag = "img"
	Input   Tag = "input"
	Li      Tag = "li"
	Link    Tag = "link"
	Main    Tag = "main"
	Meta    Tag = "meta"
	Nav     Tag = "nav"
	P       Tag = "p"
	Pre     Tag = "pre"
	Section Tag = "section"
	Small   Tag = "small"
	Span    Tag = "span"
	Strong  Tag = "strong"
	Style   Tag = "style"
	Time    Tag = "time"
	Title   Tag = "title"
	Ul      Tag = "ul"
)

// Attribute names. For a one-off dynamic name, convert directly:
// AttrName("data-id").
const (
	Alt       AttrName = "alt"
	Charset   AttrName = "charset"
	Class     AttrName = "class"
	Content   AttrName = "content"
	DateTime  AttrName = "datetime"
	Href      AttrName = "href"
	ID        AttrName = "id"
	Lang      AttrName = "lang"
	Name      AttrName = "name"
	Property  AttrName = "property"
	Rel       AttrName = "rel"
	Src       AttrName = "src"
	TitleAttr AttrName = "title"
	Type      AttrName = "type"
	Value     AttrName = "value"
)
