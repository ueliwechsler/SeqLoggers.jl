
# SeqLoggers.jl
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ueliwechsler.github.io/SeqLoggers.jl/dev)
[![Build Status](https://travis-ci.com/ueliwechsler/SeqLoggers.jl.svg?branch=master)](https://travis-ci.com/ueliwechsler/SeqLoggers.jl)
[![Coverage](https://codecov.io/gh/ueliwechsler/SeqLoggers.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ueliwechsler/SeqLoggers.jl)

`SeqLoggers.jl` is a tool for sending log events to a [`Seq` log server](https://datalust.co/seq) using the `Julia` Programming language.

`SeqLoggers.jl` extends the `AbstractLogger` interface to create log events using the macros:
- `@debug`,
- `@info`,
- `@warn` and
- `@error`.

Log events are subsequently posted to the `Seq` log server using `HTTP.jl` and the [`Seq` raw-event API](https://docs.datalust.co/docs/posting-raw-events).

Additionally, features from [`LoggingExtras.jl`](https://github.com/oxinabox/LoggingExtras.jl) are used to provide more complex logger types.

> :warning: Coping-pasting the examples on this page might introduce invisible extra characters that cannot be handled by the `Seq` server. When in doubt, replicate the examples without copying the log event strings.

## Install Seq
The `Seq` software is avabilable for free for development purposes or single-user deployment ([Installation instructions](https://docs.datalust.co/docs/getting-started)).

## Logging in julia
- https://docs.julialang.org/en/v1/stdlib/Logging/

Using the `Logging` module, log events are created by inserting a logging statement into the source code using the macros `@debug`, `@info`,  `@warn` and `@error`.

```julia
@info "Log Event with `Information` level"
```

The currently active global logger can be obtained by running
```julia
using Logging
global_logger() # ConsoleLogger(...)
```
As default, a `ConsoleLogger` is provided, which prints the logging event directly to the `Julia` REPL.

The global logger can be set to any logger `newLogger<:AbstractLogger` by calling `global_logger(newLogger)`.

Alternatively, a code section can be wrapped inside  a `with_logger` `do`-block to use a specific logger for the execution of the code  contained in the `do`-block.
```julia
Logging.with_logger(newLogger) do
    ...
end
```
Within the scope of the `do`-block, the active logger can be obtained by calling `current_logger()`.

## SeqLoggers.jl
`SeqLoggers.jl` provides a new logger type `SeqLogger<:AbstractLogger`   to replace the default logger to enable the user to post log events to a `Seq` log server.

### Basics
A `SeqLogger` is constructed by calling the constructor with the same name.
```julia
using SeqLoggers
seqLogger = SeqLogger("http://localhost:5341"; # `Seq` server url
                      min_level=Logging.Info, # define minimal level for log events
                      api_key="", # api-key for registered Apps
                      batch_size=1,
                      App="Trialrun", # additional log event properties
                      Env="UAT")
```

The resulting logger `seqLogger` posts each log event separately to the `Seq` server with url `"http://localhost:5341"`.

If the performance overhead from posting the log events separately is to high, log events can be stored and posted in a batch. The constructor keyword argument `batch_size` defines the size of a log event batch. Once the logger has received a number of log events equal to `batch_size`, all events are sent to the `Seq` log server in one post. By default, `batch_size=10`.

Therefore, for proper functionality with `batch_size>1`, it is required to use the `SeqLogger` by calling `with_logger` (and not add it as a global logger) to ensure that all log events will be sent to the log server.

```julia
Logging.with_logger(seqLogger) do
    @info "Log me into `Seq` with property user = {user}" user="Me"
end
```
In this example, besides the _global_ log event properties `App="Trialrun"` and `Env="Test"` also a _local_ log event property `user="Me"` was added.

Note, that all elements surrounded by curly brackets, e.g. `{user}`, will be replaced (on the server-side) by the corresponding log event property if it exists.

### Interaction with `LoggingExtras.jl`
`SeqLogger`s can also be combined with the functionality of [`LoggingExtras.jl`](https://github.com/oxinabox/LoggingExtras.jl) .
```
using LoggingExtras
combinedLogger = TeeLogger(Logging.current_logger(), seqLogger)
```
In this example, the `combinedLogger` logs both to the `Julia` REPL (if the current logger was a `ConsoleLogger`) and the `Seq` log server defined by `seqLogger`.

### FAQ
- The default `Seq` log server can be accessed on http://localhost:5341.
