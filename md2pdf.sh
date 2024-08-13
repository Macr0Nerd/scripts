#!/bin/bash

set -e

fold -w 80 -s $1 | pandoc -f markdown -o $(basename $1 .md).pdf
