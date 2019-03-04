#!/bin/bash

exit0=$(cat defaults.yaml | ../porta.sh 2> /dev/null| yq r - "output.result[1]")
exit0_ret=$?
exit1=$(cat errors.yaml | ../porta.sh 2> /dev/null| yq r - "output.result[1]")
exit1_ret=$?

# echo "$actual"
# echo "$expected"

echo -n "Exit code test... "
if [[ $exit0_ret -eq 0 ]]; then
  echo -n "$(tput setaf 2)OK "
else
  echo -n "$(tput setaf 1)NOK "
fi
if [[ $exit1_ret -eq 0 ]]; then
  echo -n "$(tput setaf 2)OK"
else
  echo -n "$(tput setaf 1)NOK"
fi
echo "$(tput sgr0)"
