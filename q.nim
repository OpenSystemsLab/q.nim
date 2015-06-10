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
from strtabs import hasKey

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

  QueryContext = ref object of RootObj
    root: seq[XmlNode]

proc newSelector(tag, id: string = "", classes: seq[string] = @[], attributes: seq[Attribute] = @[]): Selector =
  new(result)
  result.combinator = ' '
  result.tag = tag
  result.id = id
  result.classes = classes
  result.attributes = attributes


proc initContext(root: seq[XmlNode]): QueryContext =
  new(result)
  result.root = root

proc initContext(root: XmlNode): QueryContext =
  initContext(@[root])

proc newAttribute(n, o, v: string): Attribute =
  new(result)
  result.name = n

  if not o.isNil:
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

  if result and s.classes.len != 0:
    for class in s.classes:
      result = n.attr("class") != "" and class in n.attr("class").split()

  if result and not s.attributes.len != 0:
    for attr in s.attributes:
      let value = n.attr(attr.name)

      case attr.operator
      of '\0':
        if attr.value.isNil: # [attr] match all node has specified attribute, dont care about the value
          result = n.attrs.hasKey(attr.name)
        else: # [attr=value] value must match
          result = attr.value == value
      of '^':
        result = value.startsWith(attr.value)
      of '$':
        result = value.endsWith(attr.value)
      of '*':
        result = value.contains(attr.value)
      else:
        result = false

proc searchSimple(parent: XmlNode, selector: Selector, found: var seq[XmlNode]) =
  for child in parent.items():
    if child.kind != xnElement:
      continue

    if match(child, selector):
      found.add(child)
    if selector.combinator != '>':
      child.searchSimple(selector, found)

proc searchSimple(parents: var seq[XmlNode], selector: Selector) =
  var found: seq[XmlNode] = @[]
  for p in parents:
    p.searchSimple(selector, found)

  parents = found

proc searchCombined(parent: XmlNode, selectors: seq[Selector], found: var seq[XmlNode]) =
  var starts: seq[int] = @[0]
  var matches: seq[int]

  # matching selector by selector
  for i in 0..selectors.len-1:
    var selector = selectors[i]
    matches = @[]

    for j in starts:
      for k in j..parent.len-1:
        var child = parent[k]
        if child.kind != xnElement:
          continue

        if match(child, selector):
          if i < selectors.len-1:
            # save current index for next search
            # next selector will only search for nodes followed by this node
            matches.add(k+1)
          else:
            # no more selector, return matches
            if not found.contains(child):
              found.add(child)
          if selector.combinator == '+':
            break
    starts = matches

proc searchCombined(parents: var seq[XmlNode], selectors: seq[Selector]) =
  var found: seq[XmlNode] = @[]
  for p in parents:
    p.searchCombined(selectors, found)

  parents = found

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

      let ch = matches[i][0]
      case ch:
      of '#':
        matches[i].delete(0, 0)
        result.id = matches[i]
      of '.':
        matches[i].delete(0, 0)
        result.classes.add(matches[i])
      of '[':
        if matches[i] =~ pattributes:
          result.attributes.add(newAttribute(matches[1], matches[2], matches[3]))
      else:
        result.tag = matches[i]
  else:
    discard

proc select*(q: QueryContext, s: string = ""): seq[XmlNode] =
  result = q.root

  if s.isNil or s == "":
    return result

  var nextCombinator, nextToken: string
  var tokens = s.split()
  var selectors: seq[Selector]
  for pos in 0..tokens.len-1:
    var isSimple = true

    if pos > 0 and (tokens[pos-1] == "+" or tokens[pos-1] == "~"):
      continue

    if tokens[pos] in [">", "~", "+"]: # ignore combinators
      continue

    var selector = parseSelector(tokens[pos])
    if pos > 0 and tokens[pos-1] == ">":
      selector.combinator = '>'

    selectors = @[selector]

    var i = 1
    while true:
      if pos + i >= tokens.len:
        break
      nextCombinator = tokens[pos+i]
      #  if next token is a sibling combinator
      if nextCombinator == "+" or nextCombinator == "~":
        if pos + i + 1 >= tokens.len:
          raise newException(ValueError, "a selector expected after sibling combinator: " & nextCombinator)
      else:
          break

      isSimple = false

      nextToken = tokens[pos+i+1]
      i += 2

      var tmp = parseSelector(nextToken)
      tmp.combinator = nextCombinator[0]
      selectors.add(tmp)

    if isSimple:
      result.searchSimple(selectors[0])
    else:
      result.searchCombined(selectors)
