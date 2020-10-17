module SeqLoggers

export SeqLogger, BatchSeqLogger
export Logging

using Logging
# using Logging: Debug, Info, Warn, Error
using LoggingExtras
using Dates
using HTTP


include("utils.jl")
include("seq_logger.jl")
include("batched_seq_logger.jl")

end
