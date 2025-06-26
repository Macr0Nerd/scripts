#!/usr/bin/env bash

help() {
  echo "Usage: $(basename $0) [OPTIONS]
  $0 is a template for future shell scripts.

  Example: $0 -h

  Options:
    -h, --help	Outputs the help message for this command.
  "
}

parse_flag() {
  local SHIFT=0

  case $1 in
    h|help)
      help
      exit 0
      ;;
    f|file)
      if [[ -n "$2" ]]; then
        FILE="$2"
        SHIFT=1
      else
        echo 'File not specified'
        exit 1
      fi
      ;;
    *)
      echo "Unrecognized argument: $1"
      ;;
  esac

  return $SHIFT
}

POSITIONAL_ARGS=()

if [[ $# -eq 0 ]]; then
  help
  exit 0
fi

while [[ $# -gt 0 ]]; do
  if [[ $1 == --* ]]; then
    if ! parse_flag "${1#--}" "$2"; then
      shift
    fi

    shift
  elif [[ $1 == -* ]]; then
    OPTS="${1#-}"
    SHIFT=0

    if [[ $2 == -* ]]; then
      VAL=""
    else
      VAL="$2"
    fi

    for (( i=0; i<${#OPTS}; i++ )); do
      parse_flag "${OPTS:$i:1}" "$VAL"
      (( SHIFT+=$? ))
    done

    if [[ $SHIFT -ne 0 ]]; then
      shift
    fi

    shift
  else
    POSITIONAL_ARGS+=("$1")
    shift
  fi
done
