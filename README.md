# q.nim
Simple package for query HTML/XML elements using a CSS3 or jQuery-like selector syntax for [Nim](http://nim-lang.org).

This project is under development, just some basic selectors are implemented.

## Selectors
- [x] [Type selectors](http://www.w3.org/TR/css3-selectors/#type-selectors)
- [x] [Class selectors](http://www.w3.org/TR/css3-selectors/#class-html)
- [x] [ID selectors](http://www.w3.org/TR/css3-selectors/#id-selectors)
- [x] [Descendant combinator](http://www.w3.org/TR/css3-selectors/#descendant-combinators)
- [x] [Universal selector](http://www.w3.org/TR/css3-selectors/#universal-selector)
- [ ] [Attribute selectors](http://www.w3.org/TR/css3-selectors/#attribute-selectors)
- [x] [Child combinator](http://www.w3.org/TR/css3-selectors/#child-combinators)
- [ ] [Adjacent sibling combinator](http://www.w3.org/TR/css3-selectors/#adjacent-sibling-combinators)
- [ ] [General sibling combinator](http://www.w3.org/TR/css3-selectors/#general-sibling-combinators)
- [ ] [Structural pseudo-classes](http://www.w3.org/TR/css3-selectors/#structural-pseudos)

##Usage

````
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
````
