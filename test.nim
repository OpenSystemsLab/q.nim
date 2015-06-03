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
        <a href="#" id="link1">Link <span>1</span></a>
        <ul>
          <li>
            <a href="#">Link 11</a>
          </li>
          <li>
            <a href="#">Link 12</a>
          </li>
        </ul>
      </li>
      <li>
        <a href="#">Link 2</a>
      </li>
    </ul>
  </nav
</body>
</html>"""
var d = q(html)

#echo d.select("head *")
echo d.select("ul.menu > li > a")
#echo d.select("#top")

#echo d.select("p.lead")
#echo d.select(".col-sm-3")
