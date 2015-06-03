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
  <form class="form-horizontal">
    <div class="form-group">
      <label for="inputEmail3" class="col-sm-2 control-label">Email</label>
      <div class="col-sm-10">
        <input type="email" class="form-control" id="inputEmail3" placeholder="Email">
      </div>
    </div>
    <div class="form-group">
      <label for="inputPassword3" class="col-sm-2 control-label">Password</label>
      <div class="col-sm-10">
        <input type="password" class="form-control" id="inputPassword3" placeholder="Password">
      </div>
    </div>
    <div class="form-group">
      <div class="col-sm-offset-2 col-sm-10">
        <div class="checkbox">
          <label>
            <input type="checkbox"> Remember me
          </label>
        </div>
      </div>
    </div>
    <div class="form-group">
      <div class="col-sm-offset-2 col-sm-10">
        <button type="submit" class="btn btn-default">Sign in</button>
      </div>
    </div>
  </form>
</body>
</html>"""
var d = q(html)

echo d.select("head *")
echo d.select("ul.menu > li > a")
echo d.select("#link1")
echo d.select("input[type=password]")
echo d.select("input[type='password']")
echo d.select("input[type=\"password\"]")
echo d.select("input[type^=pa]")
echo d.select("input[type$=ord]")
echo d.select("input[type*=ss]")
