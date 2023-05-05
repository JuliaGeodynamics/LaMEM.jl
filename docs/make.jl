using Documenter, LaMEM
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
        "Installation on HPC systems" => "man/installation_HPC.md",
        "Run LaMEM" => "man/runlamem.md",
        "Reading timesteps" => "man/readtimesteps.md",
        "List of functions" => "man/listfunctions.md",
    ],
)

deploydocs(; repo="github.com/JuliaGeodynamics/LaMEM.jl.git", devbranch="main")
