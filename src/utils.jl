function replace_invalid_character(string::AbstractString)
    substitutions = ["\\" => "/",
                     "\"" => "'",
                     "\n" => "\\n",
                     "\r" => "\\r"]
    for sub in substitutions
        string = replace(string, sub)
    end
    return string
end

"""
    stringify(; kwargs...)

Convert keywords arguments into a string that conforms the log event message structure used in the `Seq` logger.
"""
function stringify(; kwargs...)
    event_properties = Vector{String}()
    for kwarg in kwargs
        # kwarg.second could have invalid characters, kwarg.first not
        clean_kwarg_second = replace_invalid_character("$(kwarg.second)")
        property = "\"$(kwarg.first)\":\"$(clean_kwarg_second)\""
        push!(event_properties, property)
    end
    return join(event_properties, ",")
end


function to_seq_level(logLevel::Base.CoreLogging.LogLevel)
    if logLevel == Logging.Debug
        return "Debug"
    elseif logLevel == Logging.Info
        return "Info"
    elseif logLevel == Logging.Warn
        return "Warning"
    elseif logLevel == Logging.Error
        return "Error"
    end
end

"""
    joinurl(left::AbstractString, right::AbstractString)

Join the left and right part of a URL, by removing trailing frontslashes and add
an additional frontslashes if required.
"""
function joinurl(left::AbstractString, right::AbstractString)
    leftStripped = rstrip(left, '/')
    rightStripped = lstrip(right, '/')
    return join([leftStripped, rightStripped], '/')
end
