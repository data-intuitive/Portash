#!/bin/bash

actual_name=$(cat override.yaml | ../porta.sh dry-run 2> /dev/null| yq r - "function.name")
actual_command=$(cat override.yaml | ../porta.sh dry-run 2> /dev/null| yq r - "function.command")
expected_name="Default Name"
expected_command="uname -a"
# echo "$actual_name"
# echo "$actual_command"
# echo "$expected_name"
# echo "$expected_command"

echo -n "Defaults test... "
if [[ "$actual_command" == "$expected_command" ]]; then
  echo -n "$(tput setaf 2)OK "
else
  echo -n "$(tput setaf 1)NOK "
fi
if [[ "$actual_name" == "$expected_name" ]]; then
  echo -n "$(tput setaf 2)OK"
else
  echo -n "$(tput setaf 1)NOK"
fi


echo "$(tput sgr0)"
