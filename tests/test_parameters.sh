#!/bin/bash

actual=$(cat parameters.yaml | ../porta.sh dry-run 2> /dev/null | yq r - "output.result[1]")
expected="foo --first_parameter bar --second_parameter foobar"
# echo "$actual"
# echo "$expected"

echo -n "Parameter test... "
if [[ "$actual" == *"$expected" ]]; then
  echo -n "$(tput setaf 2)OK"
else
  echo -n "$(tput setaf 1)NOK"
fi
echo "$(tput sgr0)"
