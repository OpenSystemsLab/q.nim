import "../q"
import xmltree

var d = q(path="test.html")

echo d.select("head *")
echo d.select("ul li a")
echo d.select("ul.menu > li a")
echo d.select("ul.menu > li > a")
echo d.select("ul.menu.and > li > a")
echo d.select("#link1")
echo d.select("input[type]")
echo d.select("input[type=password]")
echo d.select("input[type='password']")
echo d.select("input[type=\"password\"]")
echo d.select("input[type^=pa]")
echo d.select("input[type$=ord]")
echo d.select("input[type*=ss]")
echo d.select("nav ul.menu ~ div + a")
