function stringify(; kwargs...)
    kwargsString = Vector{String}()
    for kwarg in kwargs
        push!(kwargsString, "\"$(kwarg.first)\":\"$(kwarg.second)\"")
    end
    return join(kwargsString, ",")
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
