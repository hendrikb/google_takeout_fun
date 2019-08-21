#!/usr/bin/env bash

original=$1

outputfile=raw_json

echo "> INPUT: $original"
ls -lash "$original"

echo "> Flattening google location history into $outputfile"
jq --arg timefmt '%Y-%m-%dT%H:%M:%SZ' -f 00_jq_filter -c "$original" > $outputfile

echo "> OUTPUT: $outputfile:"
ls -lash $outputfile
echo "> $(wc -l $outputfile) documents ready for the next steps"
