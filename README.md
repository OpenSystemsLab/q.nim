# q.nim
Simple [jQuery](http://jquery.com)-like CSS selector for [Nim](http://nim-lang.org).

This project is under development, just some basic selectors are implemented.

## Selectors

### Implemented
- [x] Type selectors
- [x] Class selectors
- [x] ID selectors
- [x] Descendant combinator

### Todo

- [ ] Universal selector
- [ ] Attribute selectors
- [ ] Child combinator
- [ ] Adjacent sibling combinator
- [ ] General sibling combinator
- [ ] Structural pseudo-classes

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
