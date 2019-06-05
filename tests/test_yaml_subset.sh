#!/bin/bash

actual=$(cat yaml_subset.yaml | ../porta.sh 2> /dev/null| yq r - "output.result[1]")
expected='Running command: uname -a'
# echo "$actual"
# echo "$expected"

echo -n "YAML subset test... "
if [[ "$actual" == *"$expected" ]]; then
  echo -n "$(tput setaf 2)OK"
else
  echo -n "$(tput setaf 1)NOK"
fi
echo "$(tput sgr0)"
