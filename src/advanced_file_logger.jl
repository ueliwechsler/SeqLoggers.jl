"""
    AdvancedFileLogger(
        dir::AbstractString, 
        file_name_pattern::AbstractString;
        log_format_function::Function=print_standard_format,
        min_level=Logging.Info
    )

Return an file logger with extra functionality (in contrast to a `FileLogger` which is only a interface to `SimpleLogger`).

### Parameters
- `dir` -- log file directory 
- `file_name_pattern` -- file name pattern for rotating log files (e.g. `raw"\\a\\c\\c\\e\\s\\s-YYYY-mm-dd-HH-MM.\\l\\o\\g")`)
- `log_format_function` -- optional, default=`print_standard_format` 
- `min_level` -- optional, default=`Logging.Info` 

### Features
- Define a `DateFormat`/`String` file pattern for rotating log messages to a new file → argument `file_name_pattern`
- Provide a custom formatting function for writting to log files → argument `log_format_function`

### Returns
A `MinLevelLogger` which includes a `DatetimeRotatingFileLogger`.
"""
function AdvancedFileLogger(
    dir_path::AbstractString, 
    file_name_pattern::AbstractString;
    log_format_function::Function=print_standard_format,
    min_level::Logging.LogLevel=Logging.Info,
)
    file_logger = DatetimeRotatingFileLogger(log_format_function, dir_path, file_name_pattern)
    return MinLevelLogger(file_logger, min_level)
end

# Adjust 
const DISPLAY_SIZE = (100, 100)
"""
    print_standard_format(io::IO, log_args::NamedTuple)

Print log message and keyword arguments in a format similar to the one used by the [`ConsoleLogger`](@ref).
"""
function print_standard_format(io::IO, log_args::NamedTuple)
    # TODO: replace by eachsplit for Julia > 1.6
    levelstr = log_args.level == Logging.Warn ? "Warning" : string(log_args.level)
    msglines = split(chomp(string(log_args.message)::String), '\n')
    
    println(io, "[", levelstr, "] ", msglines[1]) #┌

    for i in 2:length(msglines)
        println(io, "│ ", msglines[i])
    end
    n_kwargs = length(log_args.kwargs)
    for (idx, (key, val)) in enumerate(log_args.kwargs)
        kwarg_prefix = (idx == n_kwargs) ? "└ " : "├ "

        if key == :back_trace
            msglines = split(chomp(string(val)::String), '\n')
        else
            # If the kwarg is not an Exception back_trace, use the ConsoleLogger logic to display the variable
            # NOTE: for the future, it might be reasonable, to also exclude kwargs of type String from this branch
            iob = IOBuffer()
            # DisplaySize defines "how much" of the val will be printed to file
            show(IOContext(iob, :limit => true, :displaysize => DISPLAY_SIZE), "text/plain", val)
            val_str = String(take!(iob))
            msglines = split(chomp(val_str), '\n')
        end
        if length(msglines) == 1
            println(io, kwarg_prefix, key, " = ",  msglines[1])
        else
            println(io, "├ ", key, " = ", msglines[1])
            for i in 2:(length(msglines) - 1)
                println(io, "│  ", msglines[i])
            end
            if idx == n_kwargs
                println(io, "└  ", msglines[end])
            else
                println(io, "│  ", msglines[end])
            end
        end
    end
    return nothing
end
