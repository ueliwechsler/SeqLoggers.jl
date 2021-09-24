module SeqLoggers

using Logging
# using Logging: Debug, Info, Warn, Error
using WorkerUtilities
using LoggingExtras
using Dates
using HTTP

include("utils.jl")

include("loggers.jl")
export SeqLogger

include("logging_extras.jl")

# TODO: add load logger from config
# TODO: add run_with_logger

end

