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

Oh, and did I mention already that I hate it when people have to choose between
`YAML` and `JSON` for structured data?!

### What it is not (yet?)

The current intention is not to make it a universal runner script for all sorts 
of tasks. Rather, we estimate the `porta.sh` script will be modified on a 
per-project/function basis.

In other words, __Portash__ could be seen as a template for writing
Docker/Singularity _entrypoint_ scripts.

Having said that, it does allow for something similar to that. Take a look at 
the following run for instance:

```
./porta.sh example example/uname-working.yaml
```

### Dependencies

__Portash__ is heavily dependent on 
[`yq`](https://github.com/jlordiales/jyparser)
as it provides the real power of dealing with `JSON`/`YAML` content from the
command line.

## Status

Done:

- Parsing individual _paths_ in the config
- Parsing arguments (array of keywoards/options)
- Parsing parameters (array of name/value hashes)
- Option to use `porta.sh` as the wrapper script
- Option to use `porta.sh` as an include script (see `examples/read.sh`)

To do:

- Add current job configuration to the log tag at the end.
- Install `yq` prior to processing if not available.

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
function::name                = mito
io::input::data::is_pointer   = true
function::parameters[0]       = name: parameter1 value: value1
function::parameters[0].name  = parameter1
function::parameters[0].value = value1

>> Test fetching a single parameter (first one)...
parse parameter: --parameter1 value1

>> Test fetching attributes
# arguments: 1
The parsed arguments: '-q '

>> Test fetching all parameters...
# parameters: 2
The parsed parameters: '--parameter1 value1 --parameter2 value2 '
>> Error handling
function::nam does not exist = null
```
