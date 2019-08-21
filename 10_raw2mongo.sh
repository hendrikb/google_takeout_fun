#!/usr/bin/env bash

rawinputfile=$1
database=$2
collection=$3

mongoimport -d $database -c $collection $rawinputfile
