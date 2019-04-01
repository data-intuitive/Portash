#!/bin/bash

actual=$(cat tests.yaml | ../porta.sh test 2> /dev/null | yq r - "output.result[1]")
expected="Content"
# echo ">>$actual<<"
# echo ">>$expected<<"

echo -n "Argument test... "
if [[ "$actual" == "$expected" ]]; then
  echo -n "$(tput setaf 2)OK"
else
  echo -n "$(tput setaf 1)NOK"
fi
echo "$(tput sgr0)"
