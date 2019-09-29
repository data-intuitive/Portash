# Portash

> When you enter this _gate_ we expect you to hand over your _expectations_. 
You will be _rewarded_ upon your return.

## Introduction

### Rationale

When _functions_ are put in containers, often times we did not develop the 
function ourselves. It may be a Linux binary or some Python code. And even if 
we did develop the code ourselves, we often want to keep it the code itself as 
generic as possible.

On the other hand, from an operational point of view it may be that our 
container will be running as a service or rather as part of a batch pipeline.

In other words, there's the inside world inside the container and there is the 
outside world of container orchestration.

__Portash__ is what separates them from each other. You enter the container via 
`porta.sh` and exit it again via `porta.sh`.

A different way of looking at it: It's UNIX pipes on steroids.

Oh, and did I mention already that I hate it when people have to choose between
`YAML` and `JSON` for structured data?!

### Dependencies

__Portash__ is heavily dependent on 
[`yq`](https://github.com/jlordiales/jyparser)
as it provides the real power of dealing with `JSON`/`YAML` content from the
command line.

## Status and Features

Done:

- Pre and post hook scripts
- Pre and post data processing
- Multiline scripts as main command, but also as pre and post hook
- Provide test routine
- Dry-run and config parameters
- _defaults_ config and merging with additional config
- Parsing individual _paths_ in the config
- Parsing arguments (array of keywoards/options)
- Parsing parameters (hash)
- Option to use `porta.sh` as the wrapper script
- Option to use `porta.sh` as an include script (see `examples/read.sh`)

To do:

- Install `yq` prior to processing if not available.

## Use

Portash is very much created in the spirit of a UNIX command line tool. It 
takes standard input if no input file is provided as an argument and returns 
standard output by default. That's the default way of working, for example:

```
./porta.sh defaults.yaml
```

This starts Portash using the config provided in `defaults.yaml`. Don't worry, 
this configuration is just a fancy way of running `uname -a`.

Exactly the same can be obtained using UNIX pipes:

```
cat defaults.yaml | ./porta.sh
```

A Docker container can be used as well. The image is configured to run the 
OpenFaas [`fwatchdog`](https://github.com/openfaas/faas/tree/master/watchdog) 
process which effectively turns Portash into a web service. If you want to run 
it in batch mode, use it like this:

```
docker run -i dataintuitive/portash porta.sh
```

### Dry-run

In order to know what commands will be executed, a `dry-run` argument can be 
provided:

```
cat defaults.yaml | ./porta.sh dry-run
```

### Default Configuration

We want Portash to be useful inside containers as the _interface_ between the 
outside world and the world of the container. To avoid the user having to know 
what the exact configuration needs to be, Portash supports a default
configuration.

If a `defaults.yaml` file is present in the working directory, it will be used 
as the template configuration. This template configuration will then be merged 
with whatever custom configuration is provided at runtime. For instance, the 
following invocations of Portash are exactly the same:

```
./porta.sh defaults.yaml
cat defaults.yaml | ./porta.sh
echo '' | ./porta.sh
```

This way, simple modifications to the configuration can be expressed without 
too much hassle as we will show below.

### `YAML`/`JSON`

People shouldn't have to choose between both formats. `YAML` is handy because 
we can include comments, but for simple customizations of a job the following 
syntax could be used:

```
echo '{"function":{"name":"My fancy function name"}}' | ./porta.sh
```

### Effective Configuration

An argument is available to retrieve the effective configuration for a job:

```
echo '{"function":{"name":"My fancy function name"}}' | ./porta.sh config
```

This first merges the input with the default configuration and prints the 
effective config to standard output.

### Data Processing

Data processing before and after the main process has run is supported. This is 
the example from the tests:

```yaml
function:
  name: io test yaml
  command: cat data/test_input_to.tsv | sed "s/a/x/" > data/test_output_from.tsv
io:
  in:
    command: tr ',' '\t' < data/test_input_from.csv > data/test_input_to.tsv
    from:
      from_format: csv
      from_file: csv
    to:
      to_format: tsv
      to_file: tsv
  out:
    command: tr '\t' ',' < data/test_output_from.tsv > data/test_output_to.csv
    from:
      input_format: tsv
      input_file: tsv
    to:
      output_format: csv
      output_file: csv

```

In this case, a `csv` file is first transformed in a `tsv` file, one character 
is modified as the main process and then at the end the result is transformed 
into a `tsv` file again.

The `from` and `to` fields currently are not (yet) used by Portash, but may be 
handy for documentation purposes.

The situation may occur where the post-processing step involves parsing and 
logging the YAML/JSON output from the main process. In order to achieve that, 
this information is not only sent to standard output but also stored in two 
files:

```
/tmp/portash-stdout.yaml
/tmp/portash-stdout.json
```

Please note: The whole process fails when either one of these processing steps 
results in an error. When both run successfully, the return code at the end of 
the run is the one from the main function/process.

### Hooks

Two hooks are available: `pre-hook` and `post-hook` for running scripts before 
and after the actual `command`. You can provide either a script filename or a 
script (multi-line is supported).

### Tests

It's possible to run Portash in a test mode. For instance, given the following 
configuration:

```yaml
function:
  name: Default Name
  command: uname
  test: |
    echo -n "Content" > /tmp/tests_output.txt
    cat /tmp/tests_output.txt

```

And the following command:

```sh
$ cat tests.yaml | porta.sh test
>> Test mode...
function:
  command: uname
  name: Default Name
  test: |
    echo -n "Content" > /tmp/tests_output.txt
    cat /tmp/tests_output.txt
output:
  result:
  - No pre-hook specified
  - Content
  - No post-hook specified
  start: Sat Apr 27 16:40:19 CEST 2019
  end: Sat Apr 27 16:40:19 CEST 2019
  ok: true
  error: |-
    >>> Start of error log
    <<< End of error log
```

Please note that the main `command` defined is not run, but instead the `test` 
block is executed. This can come in handy when testing pipelines for instance.

### The `extra` yaml tag

It's allowed to add an additional tag to the YAML config file, for instance:

```yaml
extra:
  - function:
      name: nested configuration
      command: ...
```

The YAML contents of this tag is copied to a SHELL variable `$EXTRA` inside the 
portash run. This way, the variable can be used in the portash configuration 
itself. Please refer to the example `yaml_subset.yaml` under `tests`.

## Examples

### Proof-of-Concept in `porta.sh`

Given `examples-uname-working.yaml`:

```yaml
function:
  name: uname-working
  command: uname
  arguments:
    - "-a"
```

And running with

    ./porta.sh example example/uname-working.yaml

The following is expected:

```yaml
function:
  name: uname-working
  command: uname
  arguments:
  - -a
output:
  result: 'Darwin ... (redacted)'
  error: ""
```

### Example in `examples/read.sh`

From the `examples` directory, run:

    ./read.sh [input.yaml]

or if you prefer the `JSON` representation:

    ./read.sh input.json

The result should be something like this:

```
>> Test fetching simple paths from input...
function::name                   = mito
io::input::data::is_pointer      = true
function::parameters.parameter1  = value1

>> Test fetching a single parameter
value for parameter parameter2: value2
parse parameter: --parameter2 value2

>> Test fetching attributes
# arguments: 1
The parsed arguments: '-q '

>> Test fetching all parameters...
# parameters: 2
The parsed parameters: '--parameter1 value1 --parameter2 value2 '

>> Error handling
function::nam does not exist = null
```
