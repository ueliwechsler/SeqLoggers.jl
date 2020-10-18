function stringify(; kwargs...)
    eventProperties = Vector{String}()
    for kwarg in kwargs
        property = "\"$(kwarg.first)\":\"$(kwarg.second)\""
        push!(eventProperties,  replace(property, "\\" => "/"))
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
