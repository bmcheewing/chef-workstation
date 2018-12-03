#!/bin/bash

set -euo pipefail

LINT_STATUS="$(grep -r -I --color=auto -o --with-filename -n -P '[^\x00-\x7F]' ./www/site/content/docs &> /dev/null ; echo $?)"

if [ "$LINT_STATUS" == 1 ]; then
  echo "Success!"
  exit 0
else
  echo "Failure!"
  grep -r -I --color=auto -o --with-filename -n -P '[^\x00-\x7F]' ./www/site/content/docs
  if [ "$LINT_STATUS" == 0 ]; then
    exit 1
  else
    exit $LINT_STATUS
  fi
fi
[i `want to contribute but i a dont know if i a am writing in the rite place
shallow breathing this moment only nt doing it wrong im doing the best i can 
all is well 
gold is making a move in this moment thers only this i realiz what im suppode to do i
must study how to use computer 
overlooked unoticed all is well 
light work feel it 
"unsupervised learning"
exploration agrred with noone 
fantastic now what 
strange new atms
blow it uo into a trlion stars 
"EPIC" 201613023 here goes nothung find it 
lets solve a problem the razors edge no dress rehersals 
