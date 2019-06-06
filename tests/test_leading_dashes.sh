#!/bin/bash

actual=$(cat leading_dashes.yaml | ../porta.sh 2> /dev/null | yq r - "output.result[1]")
expected="-----"
# echo "$actual"
# echo "$actual"

echo -n "Leading dashes test... "
if [[ "$actual" == "$expected" ]]; then
  echo -n "$(tput setaf 2)OK "
else
  echo -n "$(tput setaf 1)NOK "
fi

echo "$(tput sgr0)"
