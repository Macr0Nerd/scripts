#!/bin/bash

HTTPS=$(git remote get-url origin | sed 's+https://github.com/+git@github.com:+g' -)

git remote set-url origin $HTTPS
