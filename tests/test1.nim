import pegs

let
  attribute = "[a-zA-Z][a-zA-Z0-9_\\-]*"
  classes = "{\\.[a-zA-Z0-9_][a-zA-Z0-9_\\-]*}"
  attributes = "{\\[{" & attribute & "}\\s*({[\\*\\^\\$\\~]?}\\=\\s*[\\'\\\"]?{(\\s*\\ident\\s*)+}[\\'\\\"]?)?\\]}"
  pselectors = peg("\\s*{\\ident}?({'#'\\ident})? (" & classes & ")* "& attributes & "*")
  pattributes = peg(attributes)
  selector = "input[type=password]"

echo pselectors


if selector =~ pselectors:
  for i in 0..matches.len-1:
    echo i, "\t\t", matches[i]
