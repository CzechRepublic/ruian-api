#!/usr/bin/env bash

if [ -z "$1" ]; then
    exit 1
fi

echo $(pwd)

for i in data/vendor/$1/CSV/*.csv; do
    recode windows-1250..utf-8 "$i"
done
