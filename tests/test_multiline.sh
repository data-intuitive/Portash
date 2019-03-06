#!/bin/bash

exit0=$(cat multiline.yaml | ../porta.sh 2> /dev/null| yq r - "output.result[0]")
exit0_ret=$?

# echo "$actual"
# echo "$expected"

echo -n "Multiline test... "
if [[ $exit0_ret -eq 0 ]]; then
  echo -n "$(tput setaf 2)OK "
else
  echo -n "$(tput setaf 1)NOK "
fi
lines=$(echo "$exit0" | wc -l )
if [[ $lines -eq 2 ]]; then
  echo -n "$(tput setaf 2)OK"
else
  echo -n "$(tput setaf 1)NOK"
fi
echo "$(tput sgr0)"
