#!/bin/bash

# Clean up files before running test
rm data/test_input_to.tsv
rm data/test_output*

command=$(cat io.yaml | ../porta.sh) # 2> /dev/null | yq r - "output.result[1]")
expected=$(tail -n 1 data/test_output_to.csv)
actual="x, b, c, d"
# echo "$actual"
# echo "$expected"

echo -n "IO test... "
if [[ "$actual" == "$expected" ]]; then
  echo -n "$(tput setaf 2)OK"
else
  echo -n "$(tput setaf 1)NOK"
fi
echo "$(tput sgr0)"
