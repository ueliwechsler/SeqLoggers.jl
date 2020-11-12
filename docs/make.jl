using SeqLoggers
using Documenter

makedocs(;
    modules=[SeqLoggers],
    authors="Ueli Wechsler <ueli.wechsler@outlook.com> and contributors",
    repo="https://github.com/ueliwechsler/SeqLoggers.jl/blob/{commit}{path}#L{line}",
    sitename="SeqLoggers.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://ueliwechsler.github.io/SeqLoggers.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ueliwechsler/SeqLoggers.jl.git",
)
