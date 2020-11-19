
# SeqLoggers.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ueliwechsler.github.io/SeqLoggers.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ueliwechsler.github.io/SeqLoggers.jl/dev)
[![Build Status](https://github.com/ueliwechsler/SeqLoggers.jl/workflows/CI/badge.svg)](https://github.com/ueliwechsler/SeqLoggers.jl/actions)
[![Build Status](https://travis-ci.com/ueliwechsler/SeqLoggers.jl.svg?branch=master)](https://travis-ci.com/ueliwechsler/SeqLoggers.jl)
[![Coverage](https://codecov.io/gh/ueliwechsler/SeqLoggers.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ueliwechsler/SeqLoggers.jl)

`SeqLoggers` is a tool for logging event to the `Seq` logger https://datalust.co/seq for the `Julia` Programming language.

It utilizes the standard way of logging in `Julia` with the macros `@error` `@warn` `@info` `@debug`  and `AbstractLogger` interface to create log events.  

The log events are posted to the `Seq` logger using `HTTP.jl` and the raw-event API described at https://docs.datalust.co/docs/posting-raw-events.

> :warning: Note: This is an unoffical package and not yet production ready.

## Install Seq

Install Seq for free for development purposesor single-user deployment by following
the instruction on: https://docs.datalust.co/docs/getting-started

The `Seq` log can then be accessed on http://localhost:5341.

## Logging in julia
https://docs.julialang.org/en/v1/stdlib/Logging/

In Julia, the `Logging` module module provides a way to record the history and progress of a computation as a log of events. Events are created by inserting a logging statement into the source code using the macros `@error`, `@warn` `@info`, and  `@debug` (see https://docs.julialang.org/en/v1/stdlib/Logging/ for more information).

The default logger is a `ConsoleLogger` which prints the logging event directly in the `Julia` REPL.

The currently active logger can be obtained by running
```julia
using Logging
global_logger()
```
and can be changed with
```
global_logger(myFancyNewLogger)
```
where `myFancyNewLogger<:AbstractLogger`.

Alternatively, a code section can be wrapped inside  a `with_logger` `do` block to use a specific logger for the log events of that section.
```julia
Logging.with_logger(myLogger) do
    ...
end
```

## SeqLoggers

The pacakge `SeqLoggers.jl` provides a set of loggers to replace the default logger and give you the functionality to store log events on a `Seq` server.

### Basics

A `SeqLogger` is used to replace the currently active logger for a certain part of the code where the log events should be stored on the `Seq` server.

The basic `Seq` logger is called `SeqLogger` and is constructed as:
```julia
using SeqLoggers
serverUrl = "http://localhost:5341"
seqLogger = SeqLogger(serverUrl; # url of server hosting `seq`
                      minLevel=Logging.Info, # define minimal level for log events
                      apiKey="", # api-key for registered Apps
                      App="Trialrun", # additional log event properties
                      Env="Test")

```

The resulting logger posts every single log event directly to the `Seq` server `"http://localhost:5341"` (see [Advanced](#Advanced) for how this works under the hood and explanation of the optinal second argument).

The logger can be used both with `global_logger` and `with_logger`, e.g.
```julia
Logging.with_logger(seqLogger) do
    @info "Log me into `Seq` with property user = {user}" user="Me"
end
```
Note, that beside the "global" log event properties (`App="Trialrun"` and `Env="Test"`) belonging to a the `seqLogger`, we provided an additional log event property `user="Me"` which will be substituted into the log message at `{user}`.

### BatchSeqLogger
If the performance overhead introduced by the `SeqLogger` is unacceptable, the `BatchSeqLogger` might be of use which batches several log events before posting instead of posting every event one-by-one.

> :warning: Due to the structure of the `BatchSeqLogger`, it can only be used with `with_logger` and must not be set as `global_logger` to ensure that all log events will be sent.

The `BatchSeqLogger` is created similarly with 
```julia
batchSeqLogger = BatchSeqLogger(serverUrl; # url of server hosting `seq`
                      minLevel=Logging.Info, # define minimal level for log events
                      apiKey="", # api-key for registered Apps
                      batchSize=10, # number of events in batch before posting to `seq` server
                      App="Trialrun", # additional log event properties
                      Env="Test")
```
with the additional keyword argument `batchSize,` defining the number of log events stored before posting, and can be used as
```julia
Logging.with_logger(batchSize) do
    @info "Log me into `Seq` with property user = {user}" user="Me"
end
```

### LoggingExtras
The loggers provided by `SeqLoggers.jl` can also be combined with the functionality of [`LoggingExtras.jl`](https://github.com/oxinabox/LoggingExtras.jl).
```
using LoggingExtras
combinedLogger = TeeLogger(Logging.current_logger(), batchSeqLogger)
```
where the `combinedLogger` does log to both the `Julia` REPL and the `Seq` server defiend by `batchSeqLogger`.

### Advanced
TODO: add explanation of second optinal argument to `SeqLogger`


### FAQ

> :warning: Coping-pasting the examples on this page might introduce invisible extra characters that cannot be handled by the `Seq` server. When in doubt replicate the examples without copying the log strings.
