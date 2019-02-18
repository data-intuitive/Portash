#!/bin/bash

actual=$(cat arguments.yaml | ../porta.sh dry-run 2> /dev/null| yq r - "output.result[1]")
expected="foo first_argument second_argument"
# echo "$actual"
# echo "$expected"

echo -n "Argument test... "
if [[ "$actual" == *"$expected" ]]; then
  echo -n "$(tput setaf 2)OK"
else
  echo -n "$(tput setaf 1)NOK"
fi
echo "$(tput sgr0)"
