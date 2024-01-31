#!/usr/bin/env nu


def main [] {
  let column_delimiter = "@@"
  let format_spec = (echo "%(HEAD){}%(refname:short){}%(authorname){}%(authoremail){}%(committerdate:iso-strict){}%(subject)" | str replace --all "{}" $column_delimiter)
  let parse_expr = (["head", "branch", "author", "authoremail", "datetime", "msg"] | each {|it| $"{($it)}"} | str join $column_delimiter)
  ^git branch --format $format_spec
  | lines
  | parse $parse_expr
}
