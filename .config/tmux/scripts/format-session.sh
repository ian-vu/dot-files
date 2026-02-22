#!/bin/sh
s="$1"
case "$s" in
  */wt/*) printf '%s [%s]' "${s%%/wt/*}" "${s##*/wt/}";;
  *) printf '%s' "$s";;
esac
