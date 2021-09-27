
struct SeqLogger <: AbstractLogger
    server_url::String
    headers::Dict{String,String}
    min_level::Logging.LogLevel
    event_properties::Ref{String}
    event_batch::Vector{String}
    batch_size::Int
end

"""
    SeqLogger(
        server_url::AbstractString;
        min_level::Logging.LogLevel=Logging.Info,
        api_key::AbstractString="",
        batch_size::Int=10,
        event_properties...
    )

Logger to post log events to a `Seq` log server.

### Inputs
- `server_url` -- `Seq` server url (e.g. `"http://localhost:5341"`)
- `min_level` -- (optional, `default=Logging.Info`) minimal log level to filter the log events
- `api_key` --  (optional, `default=""`) API-key string for registered Applications
- `batch_size` -- (optional, `default=10`) number of log events sent to `Seq` server in single post
- `event_properties` -- (optional) global log event properties

#### Global Log Event Properties
The `SeqLogger` constructor allows to add global log event properties to the logger using   keyword-arguments.
```julia
SeqLogger("http://localhost:5341"; App="DJSON", Env="PROD", Id="24e0d145-d385-424b-b6ec-081aa17d504a")
```

#### Local Log Event Properties
For each individual log event, additional log event properties can be added which
only apply to a single log event.
```julia
@info "Log additional user id {userId}" userId="1"
```
Note: This only works, if the [`Logging.current_logger`](@ref) is of type `SeqLogger` or "contains" a `SeqLogger`.
"""
function SeqLogger(
    server_url::AbstractString;
    min_level::Logging.LogLevel=Logging.Info,
    api_key::AbstractString="",
    batch_size::Int=10,
    event_properties...
)
    url_endpoint = joinurl(server_url, "api/events/raw")
    headers = Dict("Content-Type" => "application/vnd.serilog.clef")
    if !isempty(api_key)
        headers["X-Seq-api_key"] = api_key
    end
    event_properties_str = stringify(; event_properties...)
    return SeqLogger(
        url_endpoint,
        headers,
        min_level,
        Ref(event_properties_str),
        String[],
        batch_size
    )
end

Logging.shouldlog(logger::SeqLogger, arg...) = true
Logging.min_enabled_level(logger::SeqLogger) = logger.min_level
Logging.catch_exceptions(logger::SeqLogger) = false


"""
    Logging.with_logger(@nospecialize(f::Function), logger::SeqLogger)

Extends the function [`Logging.with_logger`](@ref) for `SeqLogger`s.

### Note
After running the function `f`, the `SeqLogger` needs to flush the log events to
make sure that the entire log batch is sent to the `Seq` server.
"""
function Logging.with_logger(@nospecialize(f::Function), seqLogger::SeqLogger)
    result = Base.CoreLogging.with_logstate(f, Base.CoreLogging.LogState(seqLogger))
    flush_events(seqLogger)
    return result
end

const l = ReentrantLock()

"""
    Logging.handle_message(logger::SeqLogger, args...; kwargs...)

Extends the function [`Logging.handle_message`](@ref) for `SeqLogger`s.

### Note 
- If the event batch of the `logger` is "full", the log events are flushed.
- A `ReentrantLock` is used to make the `logger` thread-safe. 
"""
function Logging.handle_message(logger::SeqLogger, args...; kwargs...)
    lock(l)
    try
        message_args = LoggingExtras.handle_message_args(args...; kwargs...)
        event_str = parse_event_str_from_args(logger, message_args)
        push!(logger.event_batch, event_str)
        if length(logger.event_batch) >= logger.batch_size
            flush_events(logger)
        end
    finally
        unlock(l)
    end
    return nothing
end

"""
    parse_event_str_from_args(logger::SeqLogger, message_args::NamedTuple)::String

Create a log event string from the named tuple `message_args`.
"""
function parse_event_str_from_args(logger::SeqLogger, message_args::NamedTuple)
    line_event_properties = stringify(; _file=message_args.file, _line=message_args.line)
    is_error_log_event = message_args.level == Logging.Error
    # Ignore "back_trace" log event if log level is Error (use special @x option)
    log_event_kwargs = [
        key => value for (key, value) in message_args.kwargs 
        if !(is_error_log_event && key == :back_trace)
    ]
    kwarg_event_properties = stringify(; log_event_kwargs...)
    clean_log_msg = replace_invalid_character("$(message_args.message)")
    at_time = "\"@t\":\"$(now())\""
    at_msg = "\"@mt\":\"$(clean_log_msg)\""
    at_level = "\"@l\":\"$(to_seq_level(message_args.level))\""
    default_event_properties = [at_time, at_msg, at_level]
    if is_error_log_event
        back_trace = [value for (key, value) in message_args.kwargs if key == :back_trace]
        clean_exp_msg = isempty(back_trace) ? clean_log_msg : replace_invalid_character(back_trace[begin])
        at_exception = "\"@x\":\"$(clean_exp_msg)\""
        push!(default_event_properties, at_exception)
    end
    additonal_event_properties = [
        event for event in (line_event_properties,
                            kwarg_event_properties,
                            logger.event_properties[]) if !isempty(event) ]
    event_str = join([default_event_properties..., additonal_event_properties...], ",")
    return "{$event_str}"
end

"""
    flush_events(logger::SeqLogger)

Post all log events contained in the event batch of `logger` to the `Seq` server and 
clear the event batch afterwards.
"""
function flush_events(logger::SeqLogger)
    if !isempty(logger.event_batch)
        eventBatchJson = join(logger.event_batch, "\n")
        empty!(logger.event_batch)
        post_log_events(logger, eventBatchJson)
    end
    return nothing
end

"""
    flush_current_logger()

Post the events in the logger batch event for the logger for the current task,
or the global logger if none is attached to the task.

### Note
In the main moduel of `Atom`, the `current_logger` is `Atom.Progress.JunoProgressLogger()`.
Therefore, if you set `SeqLogger` as a [Logging.global_logger](@ref) in in `Atom`
use [`flush_global_logger`](@ref).
"""
function flush_current_logger()
    current_logger = Logging.current_logger()
    flush_events(current_logger)
    nothing
end

"""
    flush_global_logger()

Post the events in the logger batch event for the global logger.

### Note
If the logger is run with [`Logging.with_logger`](@ref), this is considered a
current logger [Logging.current_logger](@ref) and  [`flush_current_logger`](@ref).
needs to be used.
"""
function flush_global_logger()
    current_logger = Logging.global_logger()
    flush_events(current_logger)
    nothing
end

""" 
    post_request(logger::SeqLogger, json_str::AbstractString)

Send POST request with body `json_str` to `Seq` server.
"""
function post_log_events(logger::SeqLogger, json_str::AbstractString)
    return HTTP.request("POST", logger.server_url, logger.headers, json_str)
end 

"""
    event_property!(logger::SeqLogger; kwargs...)

Add one or more event properties to the list of global event properties in `logger`.

### Example
```julia
event_property!(logger, user="Me", userId=1)
```
### Note
If a new event property with identical name as an existing on is added with
`event_property!`, the existing property in `new_event_properties` is not
replaced, the new property is just added to `new_event_properties`.
However, this still works since on the `Seq` side the raw post events considers the last property key as the final one if more than one has the same key.
"""
function event_property!(logger::SeqLogger; kwargs...)
    new_event_properties = stringify(; kwargs...)
    if isempty(logger.event_properties[])
        logger.event_properties[] = new_event_properties
    else
        logger.event_properties[] = join([logger.event_properties[],
                                          new_event_properties], ",")
    end
    return nothing
end


"""
    run_with_logger(f::Function, logger::AbstractLogger, args...)

Helper function that applies advanced event logging to the execution of `f(args...)`.

In addition to normal log events (`@info`, ...), the logger catches exceptions
to create error log events. Afterwards, the exception will continue propagation
as if it had not been caught.

### Inputs
- `f` -- function to execute
- `args` -- function arguments

### Retunrs
Result from applying `f(args...)` including thrown exceptions.

### Notes
The function `run_with_logger` applies a new logger to the function call
`f(args...)`. All loggers applied on a "higher level" are replaced for the lifespan
of the function call.

### Example
```julia
logger = ConsoleLogger(stderr, Logging.Info)
run_with_logger(logger, -3) do number
    @info "Compute square root for negative number: \$number"
    sqrt(number)
end
```
"""
function run_with_logger(f::Function, logger::AbstractLogger, args...)
    with_logger(logger) do
        # If there is an error in the function call, catch the exception, create
        # a log event and rethrow the exception.
        try
            return f(args...)
        catch exception
            back_trace = sprint(showerror, exception, catch_backtrace())
            exception_message = sprint(showerror, exception)
            # SeqLogger extract the back_trace `parse_event_str_from_args` 
            @error exception_message back_trace=back_trace
            # Loggers including a SeqLogger needs to flash the event batch before rethrowing
            flush_events(logger)
            rethrow()
        end
    end
end
