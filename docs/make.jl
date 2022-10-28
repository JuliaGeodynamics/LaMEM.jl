using Documenter, LaMEM, PythonCall
push!(LOAD_PATH, "../src/")

@info "Making documentation..."
makedocs(;
    sitename="LaMEM.jl",
    authors="Boris Kaus and contributors",
    modules=[LaMEM],
    format=Documenter.HTML(; prettyurls=get(ENV, "CI", nothing) == "true"), # easier local build
    pages=[
        "Home" => "index.md",
        "Installation" => "man/installation.md",
        "List of functions" => "man/listfunctions.md",
    ],
)

deploydocs(; repo="github.com/JuliaGeodynamics/LaMEM.jl.git", devbranch="main")
