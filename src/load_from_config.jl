# ====================================================================
# Load Different Logger
# ====================================================================
"""
    load_logger_from_config(file_path::AbstractString)::TeeLogger

Create a combined logger from a config file path.

### Note
A combined logger is a `TeeLogger` struct that allows to send the same log message to 
all loggers included in the combined logger at once.
"""
function load_logger_from_config(file_path::AbstractString)
    json_string = read(file_path, String)
    json3_dict = JSON3.read(json_string) #, Dict
    return load_logger_from_config(json3_dict)
end

"""
    load_logger_from_config(config::Dict)::TeeLogger

Create a `TeeLoger`, a collection of logger, from a configuration `Dict`.

### Note
-  A `TeeLogger` struct allows to send the same log message  to  all loggers included in the `TeeLoger` at once.
- The configuration `Dict` requires as `"logging"` field, see example for more details.

### Example 
```julia
config = Dict(
    ...,
    "logging" => [
        # logger_type => logger_config_dict,
        "SeqLogger" => Dict(...),
        ...
    ],
    ...
)
```

### Returns
`TeeLogger` as defined in `config`
"""
function load_logger_from_config(config::AbstractDict)
    loggers = [
        get_logger(logger_specs) for logger_specs in config["logging"]
    ]
    return TeeLogger(loggers...)
end

# ====================================================================
# Load Single Logger
# ====================================================================
"""
    load_seqlogger(logger_config::AbstractDict)::Union{SeqLogger, TransformerLogger}

Return a `SeqLogger` or `TransformerLogger` according to `logger_config`.

### Config Parameters
- `"server_url"` -- required
- `"min_level"` -- required (`"DEBUG", "INFO", "WARN", "ERROR"`)
- `"transformation"` -- optional, default `identity`
- `"api_key"` -- optional, default `""`
- `"batch_size"` -- optional, default `10`

All other config parameters are used as global event properties.

### Example
```julia
log_dict = Dict(
    "logger_type": "SeqLogger", 
    "server_url" => "http://subdn215:5341/",
    "min_level" => "INFO",
    "batch_size" => 12,
    "App" => "SeqLoggers_Test",
    "Env" => "Test"
)
seq_logger = SeqLoggers.load_seqlogger(log_dict)
```
"""
function load_seqlogger(logger_config::AbstractDict)
    server_url = logger_config["server_url"]
    min_level = logger_config["min_level"] |> get_log_level
    transformation_str = get(logger_config, "transformation", "identity")
    transformation = transformation_str |> get_transformation_function

    # Create a NamedTuple from remaining Config Keyvalue Pairs
    kwarg_keys = filter(
        key -> string(key) ∉ ["server_url", "min_level", "transformation"], keys(logger_config)
    )
    kwarg_keys_names = Tuple(Symbol(key) for key in kwarg_keys)
    kwarg_keys_values = [logger_config[key] for key in kwarg_keys]
    kwarg_keys = NamedTuple{kwarg_keys_names}(kwarg_keys_values)
    return SeqLogger(
        server_url; min_level=min_level, kwarg_keys...
    ) |> transformation
end

"""
    load_consolelogger(logger_config::AbstractDict)::Union{ConsoleLogger, TransformerLogger}

Return a `ConsoleLogger` or `TransformerLogger` according to `logger_config`.

### Config Parameters
- `"min_level"` -- required (`"DEBUG", "INFO", "WARN", "ERROR"`)
- `"transformation"` -- optional, default `identity`

### Example
```julia
logging_config = Dict(
    "logger_type": "ConsoleLogger", 
    "min_level" => "ERROR",
    "transformation" => "add_timestamp",
)

seq_logger = SeqLoggers.load_consolelogger(log_dict)
```
"""
function load_consolelogger(logger_config::AbstractDict)
    min_level = logger_config["min_level"] |> get_log_level
    transformation_str = get(logger_config, "transformation", "identity")
    transformation = transformation_str |> get_transformation_function
    return ConsoleLogger(stderr, min_level) |> transformation
end

"""
    load_consolelogger(logger_config::AbstractDict)::AbstractLogger

Return a `MinLevelLogger{FileLogger}` or `TransformerLogger` according to `logger_config`.

### Config Parameters
- `"file_path"` -- required
- `"min_level"` -- required (`"DEBUG", "INFO", "WARN", "ERROR"`)
- `"append"` -- optional, default `true`, append to file if `true`, otherwise truncate file. (See [`LoggingExtras.FileLogger`](@ref) for more information.)
- `"transformation"` -- optional, default `identity`


### Example
```julia
logging_config = Dict(
    "logger_type": "FileLogger", 
    "file_path" => "C:/Temp/test.log",
    "min_level" => "ERROR",
    "append" => true,
    "transformation" => "add_timestamp",
)
seq_logger = SeqLoggers.load_filelogger(log_dict)
```
"""
function load_filelogger(logger_config::AbstractDict)
    min_level = logger_config["min_level"] |> get_log_level
    file_path = logger_config["file_path"]
    append = get(logger_config, "append", true)
    transformation_str = get(logger_config, "transformation", "identity")
    transformation = transformation_str |> get_transformation_function
    return MinLevelLogger(FileLogger(file_path; append=append), min_level) |> transformation
end

"""
    load_advanced_filelogger(logger_config::AbstractDict)::AbstractLogger

Return a `DatetimeRotatingFileLogger` or `TransformerLogger` according to `logger_config`.

### Config Parameters
- `"dir_path"` -- required
- `"min_level"` -- required (`"DEBUG", "INFO", "WARN", "ERROR"`)
- `"file_name_pattern"` -- required e.g. `"\\a\\c\\c\\e\\s\\s-YYYY-mm-dd-HH-MM.\\l\\o\\g"`
- `"transformation"` -- optional, default `identity`

### Example
```julia
logging_config = Dict(
    "logger_type": "AdvancedFileLogger", 
    "dir_path" => "C:/Temp",
    "min_level" => "ERROR",
    "file_name_pattern" => "\\a\\c\\c\\e\\s\\s-YYYY-mm-dd-HH-MM.\\l\\o\\g",
    "transformation" => "add_timestamp",
)
seq_logger = SeqLoggers.load_advanced_filelogger(log_dict)
```
"""
function load_advanced_filelogger(logger_config::AbstractDict)
    min_level = logger_config["min_level"] |> get_log_level
    dir_path = logger_config["dir_path"]
    file_name_pattern = logger_config["file_name_pattern"]

    transformation_str = get(logger_config, "transformation", "identity")
    transformation = transformation_str |> get_transformation_function

    return AdvancedFileLogger(
        dir_path,
        file_name_pattern;
        log_format_function=print_standard_format,
        min_level=min_level
    ) |> transformation
end

# ====================================================================
# Logger Type Mapping and Register
# ====================================================================
"""
    get_logger(logger_config::AbstractDict)::AbstractLogger

Create logger struct from logger type name and `Dict` with required parameters.

By default, the following logger types are supported:
- `"SeqLogger"` → [`SeqLogger`](@ref)
- `"ConsoleLogger"` → [`ConsoleLogger`](@ref)
- `"FileLogger"` → [`FileLogger`](@ref)

Use [`register_logger!`](@ref) to add custom `AbstractLogger`s.
"""
function get_logger(logger_config::AbstractDict)
    logger_type = get(logger_config, "logger_type", nothing)
    if isnothing(logger_type)
        throw(ArgumentError("Logger config doesn't have a `\"logger_type\"` field."))
    end
    logger_constructor = get(LOGGER_TYPE_MAPPING, logger_config["logger_type"], nothing)
    if isnothing(logger_constructor)
        throw(
            ArgumentError(
                "There is no logger corresponding to the key `$logger_type`. " *
                "Available options are $(collect(keys(LOGGER_TYPE_MAPPING))). " *
                "Use `register_logger!` to add new logger types."
            )
        )
    end
    return logger_constructor(logger_config)
end

""" 
    register_logger!(logger_type::AbstractString, logger_constructor::Function)

Register a new logger type.

Registering enables the user to use custom `AbstractLogger` struct, defined outside of `SeqLoggers`,
to be used with [`load_logger_from_config`](@ref).
"""
function register_logger!(logger_type::AbstractString, logger_constructor::Function)
    if haskey(LOGGER_TYPE_MAPPING, logger_type)
        @warn "Logger type `$logger_type` already exists and will be overwritten"
    end
    LOGGER_TYPE_MAPPING[logger_type] = logger_constructor
    return nothing
end

const LOGGER_TYPE_MAPPING = Dict(
    "SeqLogger" => load_seqlogger,
    "ConsoleLogger" => load_consolelogger,
    "FileLogger" => load_filelogger,
    "AdvancedFileLogger" => load_advanced_filelogger,
)

# ====================================================================
# Transformation Function and Register
# ====================================================================

"""
    get_transformation_function(key::String)

Convert a string (from config) into a transformation function.

By default, the following transformation functions are supported:
- `"identity"` → [`identity`](@ref): no transformation
- `"add_timestamp"` → [`add_timestamp`](@ref): add timestamp at the beginning of log message

Use [`register_transformation_function!`](@ref) to add custom transformation functions.
"""
function get_transformation_function(key::String)
    return LOGGER_TRANSFORMATION_MAPPING[key]
end

"""
    register_transformation_function!(key::AbstractString, transformation_function::Function)

Register new transformation function.

Registering enables the user to use custom transformation functions, defined outside of `SeqLoggers`,
to be used with [`load_logger_from_config`](@ref).
"""
function register_transformation_function!(key::AbstractString, transformation_function::Function)
    LOGGER_TRANSFORMATION_MAPPING[key] = transformation_function
    return nothing
end

const STANDARD_DATETIME_FORMAT = "yyyy-mm-dd HH:MM:SS"

"""
add_timestamp(logger::AbstractLogger)

Logger transformation function that prepends a timestamp to a logging message.
"""
add_timestamp(logger) =
    TransformerLogger(logger) do log
        merge(log, (; message="$(Dates.format(now(), STANDARD_DATETIME_FORMAT)): $(log.message)"))
    end

const LOGGER_TRANSFORMATION_MAPPING = Dict(
    "identity" => identity,
    "add_timestamp" => add_timestamp,
)


# ====================================================================
# Log Level
# ====================================================================
"""
    get_log_level(key::String)::Logging.LogLevel

Return the `Loggin.LogLevel` corresponding to the input string.
"""
function get_log_level(key::String)
    log_level = get(LOG_LEVEL_MAPPING, uppercase(key), nothing)
    if isnothing(key)
        throw(
            ArgumentError(
                "There is no log level corresponding to the key $key." *
                "Available options are $(collect(keys(LOG_LEVEL_MAPPING)))"
            )
        )
    end
    return log_level
end

const LOG_LEVEL_MAPPING = Dict(
    "INFO" => Logging.Info,
    "INFORMATOIN" => Logging.Info,
    "DEBUG" => Logging.Debug,
    "WARN" => Logging.Warn,
    "WARNING" => Logging.Warn,
    "ERROR" => Logging.Error,
)

