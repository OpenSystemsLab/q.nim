#
#          Nim's Unofficial Library
#        (c) Copyright 2015 Huy Doan
#
#    See the file "LICENSE", included in this
#    distribution, for details about the copyright.
#

## This module is a Simple package for query HTML/XML elements
## using a CSS3 or jQuery-like selector syntax

import re
import strutils
import htmlparser
import xmltree
from streams import newStringStream

let
  relement = re("^([a-zA-Z]+)$")
  rid = re("^([a-zA-Z]*)\\#([a-zA-Z0-9_-]+)$")
  rclass = re("^([a-zA-Z]*)\\.([a-zA-Z][a-zA-Z0-9_-]*)$")
  ratrribute = re("^([a-zA-Z]*)\\[([\\w-]+)([=~\\|\\^\\$\\*]?)=?[\"']?([^\\]\"']*)[\"']?\\]")

type
  Combinator = enum
    Descendant
    Child
    Sibling
    Adjacent

  Operator = enum
    Equals
    StartsWith
    EndsWith
    Contains

  Attribute = ref object of RootObj
    name: string
    operator: Operator
    value: string

  QueryContext = ref object of RootObj
    combinator: Combinator
    root: seq[XmlNode]
    tag: string
    id: string
    class: string
    attribute: Attribute


proc initContext(root: seq[XmlNode]): QueryContext =
  new(result)
  result.combinator = Descendant
  result.root = root

proc initContext(root: XmlNode): QueryContext =
  initContext(@[root])

proc reset(q: QueryContext) =
  q.combinator = Descendant
  q.tag = ""
  q.id = ""
  q.class = ""
  q.attribute = nil


proc newAttribute(n, o, v: string): Attribute =
  new(result)
  result.name = n
  result.value = v
  case o:
  of "=":
    result.operator = Equals
  of "^":
    result.operator = StartsWith
  of "$":
    result.operator = EndsWith
  of "*":
    result.operator = Contains
  else:
    raise newException(ValueError, "invalid attribute operator")


proc `$`*(q: QueryContext): string =
  result = $q.root

proc q*(n: XmlNode): QueryContext =
  initContext(n)

proc q*(n: seq[XmlNode]): QueryContext =
  initContext(n)

proc q*(html, path: string = ""): QueryContext =

  if html == "" and path == "":
    return nil

  var node: XmlNode
  if html == "" and path != "":
    node = loadHtml(path)
  else:
    node = parseHtml(newStringStream(html))

  result = initContext(@[node])


proc findAll(n: XmlNode, result: var seq[XmlNode], ctx: QueryContext) =
  for child in n.items():
    if child.kind != xnElement:
      continue

    var match = false

    # match tag if tag specified
    match = ctx.tag == "" or ctx.tag == "*" or child.tag == ctx.tag

    if ctx.id != "":
      match = child.attr("id") == ctx.id

    if ctx.class != "":
        match = child.attr("class") != "" and ctx.class in child.attr("class").split()

    if not ctx.attribute.isNil:
      let value = child.attr(ctx.attribute.name)
      case ctx.attribute.operator
      of Equals:
        match = ctx.attribute.value == value
      of StartsWith:
        match = value.startsWith(ctx.attribute.value)
      of EndsWith:
        match = value.endsWith(ctx.attribute.value)
      of Contains:
        match = value.contains(ctx.attribute.value)

    if match:
      result.add(child)

    if ctx.combinator == Descendant:
      child.findAll(result, ctx)

proc findAll(result: var seq[XmlNode], ctx: QueryContext) =
  var found: seq[XmlNode] = @[]
  for n in result:
    n.findAll(found, ctx)
  result = found

proc select*(q: QueryContext, selector: string = ""): seq[XmlNode] =
  result = q.root

  if selector.isNil or selector == "":
    return result

  var tokens = selector.split()
  for i in 0..tokens.len-1:

    # reset filter params
    q.reset()

    # check if previous token is a combinator
    if i > 0:
      let prevToken = tokens[i-1]

      case tokens[i-1]:
      of ">": # Child combinator
        q.combinator = Child
      of "~": # Adjacent sibling combinator
        q.combinator = Sibling
      of "+": # General sibling combinator
        q.combinator = Adjacent
      else: #Descendant combinator
        q.combinator = Descendant

    let token = tokens[i]

    # Combinators
    if token in [">", "~", "+"]:
      discard

    # Universal selector
    elif token == "*":
      result.findAll(q)

    # Type selector
    elif token =~ relement:
      q.tag = token
      result.findAll(q)

    # ID selector
    elif token =~ rid:
      q.tag = matches[0]
      q.id = matches[1]
      result.findAll(q)

    # Class selector
    elif token =~ rclass:
      q.tag = matches[0]
      q.class = matches[1]
      result.findAll(q)

    # Attribute selector
    elif token =~ ratrribute:
      q.tag = matches[0]
      q.attribute = newAttribute(matches[1], matches[2], matches[3])
      result.findAll(q)

    else:
      result = @[]
