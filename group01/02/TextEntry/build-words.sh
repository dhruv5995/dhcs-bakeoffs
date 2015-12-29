#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
  >&2 echo "usage: $0 [<corpus>]"
  >&2 echo "    accepts corpus on stdin or as first argument"
  >&2 echo "    prints to stdout"
fi

corpus="${1:-/dev/stdin}"

cat "$corpus" | awk '{ print $2 }'

