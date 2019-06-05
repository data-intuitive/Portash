#!/usr/bin/env bash

# ____            _              _
# |  _ \ ___  _ __| |_ __ _   ___| |__
# | |_) / _ \| '__| __/ _` | / __| '_ \
# |  __/ (_) | |  | || (_| |_\__ \ | | |
# |_|   \___/|_|   \__\__,_(_)___/_| |_|

echoerr() { echo "$@" 1>&2; }

# Prefix for dry-running
PREFIX='echo Running command: '

show_usage() {
  echo ""
  echo "This script takes YAML or JSON as standard input to describe a process to be run."
  echo ""
  echo "  Usage: "$0" [ test | dry-run | config ]"
  echo ""
  echo "  test:    Run the test(s)"
  echo "  dry-run: Don't actually run the command, but 'echo' the command to be run"
  echo "  config:  Return the effective configuration"
  echo ""
  echo "For more information, see: https://github.com/data-intuitive/Portash"
  echo ""
  exit 1
}

# Retrieve the content of a path
# $1: the input, JSON or YAML
# $2: string denoting the path, dots separate levels
get_path() {
  local input=$1
  local path=$2
  out=$(echo "$input" | yq r - -- "$2" 2> /dev/null)
  ret=$?
  if [ $ret -ne 0 ]; then
    echoerr "YAML/JSON parsing error in get_path(), please check input"
    exit 1
  else
    echo "$out"
  fi
}

# Add content
put_path() {
  local input=$1
  local path=$2
  local content=$3
  out=$(echo "$input" | yq w - "$2" "$3" 2> /dev/null)
  ret=$?
  if [ $ret -ne 0 ]; then
    echoerr "YAML/JSON parsing error in put_path(), please check input"
    exit 1
  else
    echo "$out"
  fi
}

# Add content
add_path() {
  local input=$1
  local path=$2
  local content=$3
  out=$(echo "$input" | yq w - "$2""[+]" "$3" 2> /dev/null)
  ret=$?
  if [ $ret -ne 0 ]; then
    echoerr "YAML/JSON parsing error in put_path(), please check input"
    exit 1
  else
    echo "$out"
  fi
}

# Convenience function to count the number of elements in an array
nr_arguments() {
  local input=$1
  local path=$2
  # Select arguments block
  arguments=$(echo "$input" | yq r - -- "$path" 2> /dev/null)
  ret=$?
  if [ $ret -ne 0 ]; then
    echoerr "YAML/JSON parsing error in nr_arguments(), please check input"
    exit 1
  fi
  # Number of arguments
  local N=0
  if [ "$arguments" != "null" ]; then
    N=$(echo "$arguments" | yq r - '[*]' | wc -l | xargs)
  fi
  echo -n "$N"
}

# Parse all arguments in an array
#   - YAML/JSON blob
#   - path to the array
# Output: string with all arguments
# ------------------------------------------------
parse_arguments() {
  local input=$1
  local path=$2
  # Select arguments block
  N=$(nr_arguments "$input" "$path" 2> /dev/null)
  ret=$?
  if [ $ret -ne 0 ]; then
    echoerr "YAML/JSON parsing error in parse_arguments(), please check input"
    exit 1
  fi
  if [ "$N" -gt 0 ]; then
    # Loop over members of argument array
    for ((i=0; i<$N; i++))
    do
      local this_path="$path"\[$i\]
      local this_argument=$(get_path "$input" "$this_path")
      echo -n $(get_path "$this_argument")
      echo -n " "
    done
  else
    echo ""
  fi
}

# Parse 1 parameter hash [name -> value]
# Input: 1 element of the parameter array
# Output: string of the form --parameter value
# ------------------------------------------------
parse_parameter() {
  local input=$1
  parameter=$(echo "$input" | yq r - -- "name" 2> /dev/null)
  ret=$?
  if [ $ret -ne 0 ]; then
    echoerr "YAML/JSON parsing error in parse_parameter() name, please check input"
    exit 1
  else
    value=$(echo "$input" | yq r - -- "value" 2> /dev/null)
    ret=$?
    if [ $ret -ne 0 ]; then
      echoerr "YAML/JSON parsing error in parse_parameter() value, please check input"
      exit 1
    else
      echo -n "--$parameter $value"
    fi
  fi
}

# Convenience function to count the number of elements in an array
nr_parameters() {
  local input=$1
  local path=$2
  # Select parameters block
  parameters=$(echo "$input" | yq r - -- "$path" 2> /dev/null)
  ret=$?
  if [ $ret -ne 0 ]; then
    echoerr "YAML/JSON parsing error in nr_parameters(), please check input"
    exit 1
  fi
  local N=0
  if [ "$parameters" != "null" ]; then
    # Number of parameters
    N=$(echo "$parameters" | yq r - '[*].name' | wc -l | xargs)
  fi
  echo -n "$N"
 }

# Parse all parameters in an array
# Input:
#   - YAML/JSON blob
#   - path to the array
# Output: string with all parameters
# ------------------------------------------------
parse_parameters() {
  local input=$1
  local path=$2
  # Select parameters block
  N=$(nr_parameters "$input" "$path" 2> /dev/null)
  ret=$?
  if [ $ret -ne 0 ]; then
    echoerr "YAML/JSON parsing error in parse_parameters(), please check input"
    exit 1
  fi
  # Loop over members of parameter array
  if [ "$N" -gt 0 ]; then
    for ((i=0; i<$N; i++))
    do
      local this_path="$path"\[$i\]
      local this_parameter=$(get_path "$input" "$this_path")
      echo -n $(parse_parameter "$this_parameter")
      echo -n " "
    done
  else
    echo ""
  fi
}

# End of generic part
# ============================================================================

# Actual RUN function...
runner() {
  local commandline="$@"
  local LOCALPREFIX=''
  if [ "$DRY" = true ]
  then
    LOCALPREFIX="$PREFIX"
  fi
  # handle the case where multiple lines are given
  OUT=$(while read -r line; do
          eval "$LOCALPREFIX$line 2>> /tmp/err.log"
        done <<< "$commandline")
  local ret=$?
  echo "$OUT"
  if [ $ret -ne 0 ]; then
    echoerr "Something went wrong running: $commandline"
    exit 1
  fi
}

# Actual PARSER
parser() {
  local input=$1
  if [ "$MODE" == "TEST" ]; then
    command=$(get_path "$input" "function.test")
  else
    command=$(get_path "$input" "function.command")
  fi
  arguments=$(parse_arguments "$input" "function.arguments")
  parameters=$(parse_parameters "$input" "function.parameters")
  echo "$command $arguments $parameters"
}

# main function
# Supports:
# - Dry run (using `dry-run` as first argument)
# - standard input or file
main() {

  # See if this is a dry-run or not
  if [ "$1" == "dry-run" ]; then
    DRY=true
    MODE="DRY"
    echoerr ">> Dry mode on, prefixing everything with '""$PREFIX""'"
    shift
  fi

  # See if this is a test or not
  if [ "$1" == "test" ]; then
    MODE="TEST"
    echoerr ">> Test mode..."
    shift
  fi

  # See if this is a request for the default config
  if [ "$1" == "config" ]; then
    DRY=true
    MODE="CONFIG"
    echoerr ">> Default config requested..."
    shift
  fi

  # Test if standard input is effectively provided, if not show_usage
  if ! test -t 0 ; then
    # Read standard input or file as first argument
    [ $# -ge 0 -a -f "$1"  ] && input="$(cat $1)" && shift || input="$(cat)"
  else
    show_usage
    exit 1
  fi

  # Merge $input with defaults.yaml if the latter exists
  defaults="defaults.yaml"
  if [ -f "$defaults" ]; then
    if ! [ -z "$input" ]; then
      echo "$input" > /tmp/inputf.yaml
      inputf="/tmp/inputf.yaml"
      input=$(yq m "$inputf" "$defaults")
      rm /tmp/inputf.yaml
    else
      input=$(cat "$defaults")
    fi
  fi

  # Report merged config and exit
  if [ "$MODE" == "CONFIG" ]; then
    if [ -f "$defaults" ]; then
      echo "$input"
    else
      echoerr ">> No config available"
    fi
    exit 0
  fi

  # IO before
  ########################################################
  io_before=$(get_path "$input" "io.in.command")
  if [ "$io_before" != "null" ]; then
    run_io_before=$(runner "$io_before")
    io_before_ret=$?
    if [ $io_before_ret -ne 0 ]; then
      echoerr "There's a problem with pre-processing the data"
      exit 1
    fi
  fi

  # Initialize error log
  echo ">>> Start of error log" > /tmp/err.log

  # Extract 'extra' part of the config for potential later use
  export EXTRA=$(get_path "$input" "extra")

  time_start=$(date)

  # pre-hook execution if present
  prehook=$(get_path "$input" "function.pre-hook")
  if ! [[ -z "$prehook" || "$prehook" =~ ^(null)$ ]]; then
    prehook_output=$(runner "$prehook")
  else
    prehook_output="No pre-hook specified"
  fi
  parsed=$(add_path "$input" "output.result" "$prehook_output")

  # Actual command
  # Run through parser
  commandline=$(parser "$input")
  # Run command
  output=$(runner "$commandline")
  mainret=$?
  # Append output to config (may not be required)
  parsed=$(add_path "$parsed" "output.result" "$output")

  # pre-hook execution if present
  posthook=$(get_path "$input" "function.post-hook")
  if ! [[ -z "$posthook" || "$posthook" =~ ^(null)$ ]]; then
    posthook_output=$(runner "$posthook")
  else
    posthook_output="No post-hook specified"
  fi
  parsed=$(add_path "$parsed" "output.result" "$posthook_output")

  time_complete=$(date)

  parsed=$(put_path "$parsed" "output.start" "$time_start")
  parsed=$(put_path "$parsed" "output.end" "$time_complete")
  ok=false
  if [ $mainret -eq 0 ]; then
    ok=true
  fi
  parsed=$(put_path "$parsed" "output.ok" "$ok")


  # Append errors to config
  echo "<<< End of error log" >> /tmp/err.log
  err=$(cat /tmp/err.log)
  parsed=$(put_path "$parsed" "output.error" "$err")
  # store parsed in a file (for later consumption in post-processing)
  echo "$parsed" > /tmp/portash-stdout.yaml
  echo "$parsed" | yq r - -j > /tmp/portash-stdout.json
  # Return parsed to standard output as well
  echo "$parsed"

  # IO After
  #######################################################
  io_after=$(get_path "$input" "io.out.command")
  if [ "$io_after" != "null" ]; then
    run_io_after=$(runner "$io_after")
    io_after_ret=$?
    if [ $io_after_ret -ne 0 ]; then
      echoerr "There's a problem with post-processing the data"
      exit 1
    fi
  fi

  if [ $mainret -ne 0 ]; then
    exit 1
  fi

}

# Some machinery to make this script easily 'sourceable' for tests
script_name=$( basename ${0#-} ) #- needed if sourced no path
this_script=$( basename ${BASH_SOURCE} )

if [[ ${script_name} = ${this_script} ]] ; then
    # running main here, otherwise leave control
    main "$@"
fi

# END
