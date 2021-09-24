"""
    abstract type PostType end

The `PostType` determines how a [`SeqLogger`](@ref) sends the log 
events to the the server. 

Options are: 
- [`ParallelPost`](@ref)
- [`SerialPost`](@ref)
- [`BackgroundPost`](@ref)
"""
abstract type PostType end

"""
    struct SerialPost <: PostType end

A `SeqLogger{SerialPost}` sends the log event to the server without any multi-threading.
"""
struct SerialPost <: PostType end

"""
    struct ParallelPost <: PostType end

A `SeqLogger{ParallelPost}` creates and runs a new Task on any available thread 
to send the log events to the server.
"""
struct ParallelPost <: PostType end

"""
    struct BackgroundPost <: PostType end

A `SeqLogger{BackgroundPost}` creates a background task and runs the background task 
to send the log events to the server.
"""
struct BackgroundPost <: PostType
    number_workers::Int
end
BackgroundPost() = BackgroundPost(one(Int))