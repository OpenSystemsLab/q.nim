import xmltree
import re

const
  whitespace = "[\\x20\\t\\r\\n\\f]*"

let
  relement = re("^" & whitespace & "([a-zA-Z]+)" & whitespace & "$")
  rid = re("^" & whitespace & "([a-zA-Z]*)\\#([a-zA-Z0-9_-]+)" & whitespace & "$")
  rclass = re("^" & whitespace & "([a-zA-Z]*)\\.([a-zA-Z][a-zA-Z0-9_-]*)" & whitespace & "$")


type
  Combinator = enum
    Descendant
    Child
    Sibling
    Adjacent

  AttributeEval = enum
    Equals
    Element
    StartsWith
    EndsWith
    Any
    Not

  Atrribute = ref object of RootObj
    name: string
    eval: AttributeEval
    value: string


  Selector = ref SelectorObj
  SelectorObj = object
    combinator: Combinator
    tag: string
    id: string
    classList: seq[string]
    attributeList: seq[Atrribute]
proc `$`(s: Selector): string =
  result = ""

  case s.combinator
  of Child:
    result &= "> "
  of Sibling:
    result &= "+ "
  of Adjacent:
    result &= "~ "
  else:
    discard

  if not s.tag.isNil:
    result &= s.tag

  if not s.id.isNil:
    result &= "#" & s.id

  if not s.classList.isNil and s.classList.len > 0:
    for c in s.classList:
      result &= "." &  c

  if not s.attributeList.isNil and s.attributeList.len > 0:
    result &= "["
    for attr in s.attributeList:
      result &= attr.name

      case attr.eval:
      of Element:
        result &= "~="
      of StartsWith:
        result &= "^="
      of EndsWith:
        result &= "$="
      of Any:
        result &= "*="
      of Not:
        result &= "!="
      else:
        discard

      result &= attr.value
    result &= "]"


proc newSelector(): Selector =
  new(result)
  result.combinator = Descendant

proc parse*(s: string): seq[Selector] =
  result = @[]

  # simple cases
  if s =~ relement:
    var selector = newSelector()
    selector.tag = matches[0]
    result.add(selector)

  if s =~ rid:
    var selector = newSelector()
    if matches[0].len > 0:
      selector.tag = matches[0]
    selector.id = matches[1]
    result.add(selector)

  if s =~ rclass:
    var selector = newSelector()
    if matches[0].len > 0:
      selector.tag = matches[0]
    selector.id = matches[1]
    result.add(selector)



when isMainModule:
  echo parse("body")
  echo parse(".body")
  echo parse("div#body   ")
  echo parse("#article")
  #discard parse("div#article.large")
  #parse("div > h2:contains(Article)")
  #parse("ul > li ~ li")
  #parse("div p + ul")
  #parse("li a[href=#] > span")
