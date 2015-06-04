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
  Attribute = ref object of RootObj
    name: string
    operator: char
    value: string

  Selector = ref object of RootObj
    combinator: char
    tag: string
    id: string
    class: string
    attribute: Attribute
    nestedSelector: Selector

  QueryContext = ref object of RootObj
    root: seq[XmlNode]
    selector: Selector

proc newSelector(tag, id, class: string = "", attribute: Attribute = nil): Selector =
  new(result)
  result.combinator = ' '
  result.tag = tag
  result.id = id
  result.class = class
  result.attribute = attribute
  result.nestedSelector = nil


proc initContext(root: seq[XmlNode]): QueryContext =
  new(result)
  result.root = root
  result.selector = newSelector()

proc initContext(root: XmlNode): QueryContext =
  initContext(@[root])

proc newAttribute(n, o, v: string): Attribute =
  new(result)
  result.name = n
  result.operator = o[0]
  result.value = v

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


proc match(n: XmlNode, s: Selector): bool =
  # match tag if tag specified
  result = s.tag == "" or s.tag == "*" or n.tag == s.tag

  if result and s.id != "":
    result = n.attr("id") == s.id

  if result and s.class != "":
    result = n.attr("class") != "" and s.class in n.attr("class").split()

  if result and not s.attribute.isNil:
    let value = n.attr(s.attribute.name)
    case s.attribute.operator
    of '=':
      result = s.attribute.value == value
    of '^':
      result = value.startsWith(s.attribute.value)
    of '$':
      result = value.endsWith(s.attribute.value)
    of '*':
      result = value.contains(s.attribute.value)
    else:
      result = false

proc searchSimple(ctx: QueryContext, n: XmlNode, result: var seq[XmlNode]) =
  for child in n.items():
    if child.kind != xnElement:
      continue

    if match(child, ctx.selector):
        result.add(child)

    if ctx.selector.combinator == ' ':
      ctx.searchSimple(child, result)

proc searchCombined(ctx: QueryContext, n: XmlNode, result: var seq[XmlNode]) =
  for i in 0..n.len()-1:
    var child = n[i]
    if child.kind != xnElement:
      continue
    
    if match(child, ctx.selector):
        var currentSelector = ctx.selector.nestedSelector
        while not currentSelector.nestedSelector.isNil:
          #if currentSelector.combinator == '~':
          echo currentSelector.tag
          for j in i..n.len()-1:
            var sibling = n[j]
            if sibling.kind == xnElement and match(sibling, currentSelector):
              echo "here ", j, " ", sibling
              result.add(sibling)

          currentSelector = currentSelector.nestedSelector


proc search(ctx: QueryContext, result: var seq[XmlNode]) =
  var found: seq[XmlNode] = @[]

  if ctx.selector.nestedSelector.isNil:
    for n in result:
      ctx.searchSimple(n, found)
  else:
    for n in result:
      ctx.searchCombined(n, found)

  result = found

proc parseSelector(token: string): Selector =
  result = newSelector()
  # Universal selector
  if token == "*":
    result.tag = "*"
  # Type selector
  elif token =~ relement:
    result.tag = token
  # ID selector
  elif token =~ rid:
    result.tag = matches[0]
    result.id = matches[1]
  # Class selector
  elif token =~ rclass:
    result.tag = matches[0]
    result.class = matches[1]
  # Attribute selector
  elif token =~ ratrribute:
    result.tag = matches[0]
    result.attribute = newAttribute(matches[1], matches[2], matches[3])
  else:
    discard

proc select*(q: QueryContext, s: string = ""): seq[XmlNode] =
  echo "Selectors: ", s
  result = q.root

  if s.isNil or s == "":
    return result

  var tokens = s.split()
  for pos in 0..tokens.len-1:

    if pos > 0 and (tokens[pos-1] == "+" or tokens[pos-1] == "~"):
      continue

    # ignore combinators
    if tokens[pos] in [">", "~", "+"]:
      discard

    var selector = parseSelector(tokens[pos])
    if pos > 0 and tokens[pos-1] == ">":
      selector.combinator = '>'

    var nextCombinator: string
    var nextSelector: string
    var nestedSelector: Selector
    var i = 1
    while true:
      if pos + i < tokens.len:
        nextCombinator = tokens[pos+i]
        #  if next token is a sibling combinator
        if nextCombinator == "+" or nextCombinator == "~":
          if pos + i + 1 >= tokens.len:
            raise newException(ValueError, "a selector expected after sibling combinator: " & nextCombinator)
        else:
            break

        nextSelector = tokens[pos+i+1]
        i += 2
        echo "nextCombinator ", nextCombinator, " nextSelector ", nextSelector

        #TODO support inifite combinators, currently only 2 supported
        if nestedSelector.isNil:
          nestedSelector = parseSelector(nextSelector)
          nestedSelector.combinator = nextCombinator[0]
        else:
          nestedSelector.nestedSelector = parseSelector(nextSelector)
          nestedSelector.nestedSelector.combinator = nextCombinator[0]

      else:
        break
    selector.nestedSelector = nestedSelector

    q.selector = selector
    q.search(result)
