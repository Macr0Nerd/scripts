#!/bin/bash

_help="Usage: $(basename $0) [OPTIONS]
$0 is a template for future shell scripts.
Example: $0 -h

Options:
	-h, --help	Outputs the help message for this command."

_basic="Usage: $0 [OPTIONS]
Try $0 --help for more information."

# Options strings
SHORT=h
LONG=help

OPTS=$(getopt --options $SHORT --long $LONG --name "$0" -- "$@")

if [[ $? != 0 ]]; then echo "Failed to parse options... exiting." >&2;
exit 1; fi

eval set -- "$OPTS"

if [[ $# = 1 ]]; then echo "$_basic"; exit 1; fi

while true; do
	case "$1" in
		-h | --help )
			echo "$_help"
			shift
			;;
		-- )
			shift
			break
			;;
	esac
done

