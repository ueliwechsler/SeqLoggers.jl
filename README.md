# SeqLoggers.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ueliwechsler.github.io/SeqLoggers.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ueliwechsler.github.io/SeqLoggers.jl/dev)
[![Build Status](https://github.com/ueliwechsler/SeqLoggers.jl/workflows/CI/badge.svg)](https://github.com/ueliwechsler/SeqLoggers.jl/actions)
[![Build Status](https://travis-ci.com/ueliwechsler/SeqLoggers.jl.svg?branch=master)](https://travis-ci.com/ueliwechsler/SeqLoggers.jl)
[![Coverage](https://codecov.io/gh/ueliwechsler/SeqLoggers.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/ueliwechsler/SeqLoggers.jl)

`SeqLoggers` is a tool for logging event to the `Seq` logger https://datalust.co/seq for the `Julia` Programming language.

It utilizes the standard way of logging in `Julia` with the macros `@error` `@warn` `@info` `@debug`  and `AbstractLogger` interface to create log events.  

The log events are posted "asynchronoulsy" to the `Seq` logger using `HTTP.jl` and the raw-event API described at https://docs.datalust.co/docs/posting-raw-events.

**!!! Note: This is an unoffical package and not production ready.**

**!!! Note: Using `SeqLoggers.jl` might introduce a considerable perfromance penalty.**
**!!! Note: Need to create documentation https://juliadocs.github.io/Documenter.jl/stable/man/hosting/**

## Install Seq)

Install Seq for free for development purposesor single-user deployment by following
the instruction on: https://docs.datalust.co/docs/getting-started

The `Seq` log can then be accessed on http://localhost:5341.

## SeqLoggers Type

A `SeqLogger` is used to replace the currently active logger for a certain part of the code where the log events should be stored in the `Seq` logger.

This is done by  and then  wrapping the code in a `with_logger` `do` block.

First, a `SeqLogger` is created with the constructor
```julia
seqLogger = SeqLogger(; serverUrl="http://localhost:5341", App="Trialrun", Env="Test")
```
where the hosting `Seq` server is defined in `serverUrl` and further keyword arguments define "global" log event properties for the logger.

The logger then can be used as follows:
```julia
@time Logging.with_logger(seqLogger) do
    @info "Log me into `Seq` with property user = {user}" user="Me"
end
```
