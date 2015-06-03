#
#          Nim's Unofficial Library
#        (c) Copyright 2015 Huy Doan
#
#    See the file "LICENSE", included in this
#    distribution, for details about the copyright.
#

## This module is a Simple CSS3 selectors for Nim

import re
import strutils
import htmlparser
import xmltree
from streams import newStringStream

let
  relement = re("^([a-zA-Z]+)$")
  rid = re("^([a-zA-Z]*)\\#([a-zA-Z0-9_-]+)$")
  rclass = re("^([a-zA-Z]*)\\.([a-zA-Z][a-zA-Z0-9_-]*)$")
  ratrribute = re("^(?P<tag>\\w+)?\\[(?P<attribute>[\\w-]+)(?P<operator>[=~\\|\\^\\$\\*]?)=?\"?(?P<value>[^\\]\"]*)\"?\\]")

type
  Combinator = enum
    Descendant
    Child
    Sibling
    Adjacent

  Q = ref object of RootObj
    combinator: Combinator
    context: seq[XmlNode]


proc newQ(nodes: seq[XmlNode]): Q =
  new(result)
  result.combinator = Descendant
  result.context = nodes

proc newQ(node: XmlNode): Q =
  newQ(@[node])

proc `$`*(q: Q): string =
  result = $q.context

proc q*(html, path: string = ""): Q =

  if html == "" and path == "":
    return nil

  var node: XmlNode
  if html == "" and path != "":
    node = loadHtml(path)
  else:
    node = parseHtml(newStringStream(html))

  result = newQ(node)


proc findAll(n: XmlNode, result: var seq[XmlNode], recursive: bool, tag, id, class: string = "") =
  for child in n.items():
    if child.kind != xnElement:
      continue

    var match = false

    match = tag == "" or tag == "*" or child.tag == tag

    if id != "" and child.attr("id") != "":
      match = child.attr("id") == id

    if class != "":
        match = child.attr("class") != "" and class in child.attr("class").split()

    if match:
      result.add(child)

    if recursive:
      child.findAll(result, recursive, tag=tag, id=id, class=class)

proc findAll(nodes: seq[XmlNode], result: var seq[XmlNode], recursive: bool, tag, id, class: string = "") =
  for n in nodes:
    n.findAll(result, recursive, tag, id, class)

proc select*(q: Q, selector: string = ""): seq[XmlNode] =
  result = q.context

  var found: seq[XmlNode]

  if selector.isNil or selector == "":
    return result

  var tokens = selector.split()
  for i in 0..tokens.len-1:
    # reset found list
    found = @[]

    if i > 0 and tokens[i-1] == ">":
      continue

    let token = tokens[i]
    echo "Token ", token

    # match simple html element
    if token =~ relement:
      result.findAll(found, true, token)
      result = found
      continue

    # match simple id selector
    if token =~ rid:
      result.findAll(found, true, matches[0], matches[1])
      result = found
      continue

    # match simple class selector
    if token =~ rclass:
      result.findAll(found, true, matches[0], class=matches[1])
      result = found
      continue

    if token =~ ratrribute:
      continue

    result = @[]
