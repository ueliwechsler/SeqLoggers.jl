function replace_invalid_character(string::AbstractString)
    substitutions = ["\\" => "/",
                     "\"" => "'",
                     "\n" => "\\n"]
    for sub in substitutions
        string = replace(string, sub)
    end
    return string
end

function stringify(; kwargs...)
    eventProperties = Vector{String}()
    for kwarg in kwargs
        # kwarg.second can have invalid chracters, kwarg.first not
        cleanKwargSecond = replace_invalid_character("$(kwarg.second)")
        property = "\"$(kwarg.first)\":\"$(cleanKwargSecond)\""
        push!(eventProperties, property)
    end
    return join(eventProperties, ",")
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

# NOTE: remove trailing or add additional frontslash
function joinurl(left, right)
    leftStripped = rstrip(left, '/')
    rightStripped = lstrip(right, '/')
    return join([leftStripped, rightStripped], '/')
end
