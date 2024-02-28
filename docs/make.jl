using Documenter
#push!(LOAD_PATH, "../src/")

push!(LOAD_PATH, dirname(@__DIR__))

using LaMEM

@info "Making documentation..."
makedocs(;
    sitename="LaMEM.jl",
    authors="Boris Kaus and contributors",
    modules=[LaMEM],
    format=Documenter.HTML(; prettyurls=get(ENV, "CI", nothing) == "true"), # easier local build
    pages=[
        "Home" => "index.md",
        "Installation" => ["General instructions" => "installation.md",
                            "Installation on HPC systems" => "installation_HPC.md"],
        "Create & run LaMEM models from julia" => ["Overview" => "juliasetups.md",
                                                    "Example 1: Sphere" => "juliasetup_example_sphere.md",
                                                    "Example 2: Volcano" => "juliasetup_LaPalma.md",
                                                    "Example 3: 2D Subduction" => "juliasetup_TMSubduction.md",
                                                    "Example 4: 3D Subduction" => "Subduction3D.md",
                                                    "Notebooks" => "juliasetup_pluto.md",
                                                    "Available functions" => "LaMEM_ModelFunctions.md",
                                                  ],
        "Run LaMEM" => "runlamem.md",
        "Reading timesteps" => "readtimesteps.md",
        "List of functions" => "listfunctions.md",
    ],
    pagesonly=true,
    warnonly=true
)

deploydocs(; repo="github.com/JuliaGeodynamics/LaMEM.jl.git", devbranch="main")
