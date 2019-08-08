#!/bin/bash

actual=$(cat long.yaml | ../porta.sh 2> /dev/null | yq r - "output.result[1]")
expected=103
actual=$(echo "$actual" | wc -l)

echo -n "Argument test... "
if [[ "$actual" == *"$expected" ]]; then
  echo -n "$(tput setaf 2)OK"
else
  echo -n "$(tput setaf 1)NOK"
fi
echo "$(tput sgr0)"
