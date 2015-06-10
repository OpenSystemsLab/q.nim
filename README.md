# q.nim
Simple package for query HTML/XML elements using a CSS3 or [jQuery](http://jquery.com)-like selector syntax for [Nim](http://nim-lang.org).

This project is in alpha stage, some features are not supported yet.

## Selectors
- [x] [Type selectors](http://www.w3.org/TR/css3-selectors/#type-selectors)
- [x] [Class selectors](http://www.w3.org/TR/css3-selectors/#class-html)
- [x] [ID selectors](http://www.w3.org/TR/css3-selectors/#id-selectors)
- [x] [Descendant combinator](http://www.w3.org/TR/css3-selectors/#descendant-combinators)
- [x] [Universal selector](http://www.w3.org/TR/css3-selectors/#universal-selector)
- [x] [Attribute selectors](http://www.w3.org/TR/css3-selectors/#attribute-selectors)
- [x] [Child combinator](http://www.w3.org/TR/css3-selectors/#child-combinators)
- [x] [Adjacent sibling combinator](http://www.w3.org/TR/css3-selectors/#adjacent-sibling-combinators)
- [x] [General sibling combinator](http://www.w3.org/TR/css3-selectors/#general-sibling-combinators)
- [ ] [Structural pseudo-classes](http://www.w3.org/TR/css3-selectors/#structural-pseudos)

##Installation
    $ nimble install q

##Changes
    0.0.2 - supports sibling combinators and multiple class, attributes selectors
    0.0.1 - initial release


##Usage

```nim
import q
import xmltree

var html = """<html>
<head>
  <tile>Example</title>
</head>
<body>
  <nav>
    <ul class="menu">
      <li class="dropdown">
        <a href="#">Link 1</a>
      </li>
      <li>
        <a href="#">Link 2</a>
      </li>
    </ul>
  </nav
</body>
</html>"""


# Parse HTML document
var doc = q(html)

# Search for nodes by css selector
echo doc.select("nav ul.menu li a")
# @[<a href="#">Link 1</a>, <a href="#">Link 2</a>]
```
