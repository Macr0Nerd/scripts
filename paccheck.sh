#!/bin/bash

PACKAGE=$1

for file in $( pacman -QL ${PACKAGE} | cut -d' ' -f2 ); do
    if [ "${test:$(( ${#test} - 1 ))" == "/" ]; then
        if [ ! -d ${file} ]; then
            echo "Directory missing: ${file}"
        fi
    else
        if [ ! -f ${file} ]; then
            echo "File missing: ${file}"
        fi
    fi
done
