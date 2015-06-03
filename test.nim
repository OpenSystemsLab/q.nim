import q
import xmltree

var d = q(path="test.html")

echo d.select("head meta")
echo d.select("div#azcarbon")
echo d.select("#top")

echo d.select("p.lead")
echo d.select(".col-sm-3")
