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

## Install Seq)

Install Seq for free for development purposesor single-user deployment by following
the instruction on: https://docs.datalust.co/docs/getting-started

The `Seq` log can then be accessed on http://localhost:5341.

## SeqLoggers Type
