#
#          Nim's Unofficial Library
#        (c) Copyright 2015 Huy Doan
#
#    See the file "LICENSE", included in this
#    distribution, for details about the copyright.
#

## This module is a Simple package for query HTML/XML elements
## using a CSS3 or jQuery-like selector syntax

import pegs
import strutils
import htmlparser
import xmltree
from streams import newStringStream

let
  attribute = "[a-zA-Z][a-zA-Z0-9_\\-]*"
  classes = "{\\.[a-zA-Z0-9_][a-zA-Z0-9_\\-]*}"
  attributes = "{\\[" & attribute & "\\s*([\\*\\^\\$\\~]?\\=\\s*[\\'\\\"]?(\\s*\\ident\\s*)+[\\'\\\"]?)?\\]}"
  pselectors = peg("\\s*{\\ident}?({'#'\\ident})? (" & classes & ")* "& attributes & "*")
  pattributes = peg("{\\[{" & attribute & "}\\s*({[\\*\\^\\$\\~]?}\\=\\s*[\\'\\\"]?{(\\s*\\ident\\s*)+}[\\'\\\"]?)?\\]}")

type
  Attribute = ref object of RootObj
    name: string
    operator: char
    value: string

  Selector = ref object of RootObj
    combinator: char
    tag: string
    id: string
    classes: seq[string]
    attributes: seq[Attribute]
    nestedSelector: Selector

  QueryContext = ref object of RootObj
    root: seq[XmlNode]
    selector: Selector

proc newSelector(tag, id: string = "", classes: seq[string] = @[], attributes: seq[Attribute] = @[]): Selector =
  new(result)
  result.combinator = ' '
  result.tag = tag
  result.id = id
  result.classes = classes
  result.attributes = attributes
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
  result.value = v
  result.operator = o[0]


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

  if result and s.classes.len != 0:
    for class in s.classes:
      result = n.attr("class") != "" and class in n.attr("class").split()

  if result and not s.attributes.len != 0:
    for attribute in s.attributes:
      let value = n.attr(attribute.name)

      case attribute.operator
      of '\0':
        result = attribute.value == value
      of '^':
        result = value.startsWith(attribute.value)
      of '$':
        result = value.endsWith(attribute.value)
      of '*':
        result = value.contains(attribute.value)
      else:
        #result = attribute.name in n.attrs()
        #TODO current xmltree module did not handle empty attribute correctly yet
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
  elif token =~ pselectors:
    for i in 0..matches.len-1:
      if matches[i].isNil:
        continue

      #echo matches[i]

      let ch = matches[i][0]
      case ch:
      of '#':
        matches[i].delete(0, 0)
        result.id = matches[i]
      of '.':
        matches[i].delete(0, 0)
        result.classes.add(matches[i])
      of '[':
        var m {.inject.}: array[0..MaxSubpatterns-1, string]
        discard matches[i].match(pattributes, m)
        if m[2].isNil:
          m[2] = ""
          m[3] = ""
        result.attributes.add(newAttribute(m[1], m[2], m[3]))
      else:
        result.tag = matches[i]
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
