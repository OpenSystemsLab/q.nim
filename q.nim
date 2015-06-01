#
#          Nim's Unofficial Library
#        (c) Copyright 2015 Huy Doan
#
#    See the file "LICENSE", included in this
#    distribution, for details about the copyright.
#

## This module is a jQuery-like library for Nim

import htmlparser
import xmltree
from streams import newStringStream

type
  Q = ref object of RootObj
    node: XmlNode

proc newQ(node: XmlNode): Q =
  new(result)
  result.node = node

proc `$`*(q: Q): string =
  result = $q.node

proc q*(html, path: string = ""): Q =

  if html == "" and path == "":
    return nil

  var node: XmlNode
  if html == "" and path != "":
    node = loadHtml(path)
  else:
    node = parseHtml(newStringStream(html))

  result = newQ(node)


proc find*(q: Q, selector: string = ""): Q =
  result = q
