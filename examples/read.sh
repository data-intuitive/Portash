#!/usr/bin/env bash

# Script with examples on how to use the functionality from `porta.sh`.

source ../porta.sh

# Argument to this script can be an input file (YAML/JSON)
# If no argument is specified, use input.yaml
[ $# -ge 0 -a -f "$1"  ] && input="$(cat $1)" && shift || input="$(cat input.yaml)"

echo ">> Test fetching simple paths from input..."
echo "function::name                   = "$(get_path "$input" "function.name")
echo "io::input::data::is_pointer      = "$(get_path "$input" "io.input.data.is_pointer")
echo "function::parameters.parameter1  = "$(get_path "$input" "function.parameters.parameter1")
echo

echo ">> Test fetching a single parameter"
parameter="parameter2"
echo "value for parameter $parameter: "$(get_path "$input" "function.parameters"."$parameter")
echo "parse parameter: "$(parse_parameter "$input" "function.parameters" "$parameter")
echo

echo ">> Test fetching attributes"
arguments=$(nr_arguments "$input" "function.arguments")
echo "# arguments: "$arguments
parsed_arguments=$(parse_arguments "$input" "function.arguments")
echo "The parsed arguments: '$parsed_arguments'"
echo

echo ">> Test fetching all parameters..."
parameters=$(nr_parameters "$input" "function.parameters")
echo "# parameters: "$parameters
parsed_parameters=$(parse_parameters "$input" "function.parameters")
echo "The parsed parameters: '$parsed_parameters'"

echo ">> Error handling"
echo "function::nam does not exist = "$(get_path "$input" "function.nam")
