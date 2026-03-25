using Documenter, DocumenterVitepress
using NodeJS_20_jll: node, npm

push!(LOAD_PATH, dirname(@__DIR__))

using LaMEM

@info "Making documentation..."
makedocs(;
    sitename="LaMEM.jl",
    authors="Boris Kaus and contributors",
    modules=[LaMEM],
    format=DocumenterVitepress.MarkdownVitepress(
        repo="github.com/JuliaGeodynamics/LaMEM.jl",
        devbranch="main",
        devurl="dev",
        build_vitepress=false,
    ),
    pages=[
        "Home" => "index.md",
        "Installation" => "installation.md",
        "Installation on HPC" => "installation_HPC.md",
        "Create & run LaMEM models from julia" => ["Overview" => "juliasetups.md",
                                                    "Example 1: Sphere" => "juliasetup_example_sphere.md",
                                                    "Example 2: Volcano" => "juliasetup_LaPalma.md",
                                                    "Example 3: 2D Subduction" => "juliasetup_TMSubduction.md",
                                                    "Example 4: 3D Subduction" => "Subduction3D.md",
                                                    "Notebooks" => "juliasetup_pluto.md",
                                                    "Available functions" => "LaMEM_ModelFunctions.md",
                                                    "Passive tracers" => "readpassivetracers.md",
                                                  ],
        "run LaMEM models the classical way" => ["Run LaMEM" => "runlamem.md",
                               "Reading timesteps" => "readtimesteps.md"],
        "List of functions" => "listfunctions.md",
    ],
    pagesonly=true,
    warnonly=true,
)

# Copy hero image to the Vitepress public folder so it's served at the unhashed path
# referenced in index.md frontmatter (Vitepress doesn't fingerprint YAML hero image paths).
public_assets = joinpath(@__DIR__, "build", ".documenter", "public", "assets")
mkpath(public_assets)
cp(joinpath(@__DIR__, "src", "assets", "SubductionSetup_3D.png"),
   joinpath(public_assets, "SubductionSetup_3D.png"); force=true)
cp(joinpath(@__DIR__, "src", "assets", "logo_LaMEM.png"),
   joinpath(public_assets, "logo_LaMEM.png"); force=true)

# Overwrite the intermediate index.md with the original (which has proper Vitepress YAML
# frontmatter). Julia's Markdown parser does not recognize YAML frontmatter, so makedocs
# corrupts it — we restore it before running Vitepress.
@info "Patching index.md with Vitepress home layout frontmatter..."
cp(joinpath(@__DIR__, "src", "index.md"),
   joinpath(@__DIR__, "build", ".documenter", "index.md"); force=true)

# Patch the generated Vitepress config to ignore dead links (some docstring field
# descriptions are mis-parsed as Markdown links by Vitepress).
config_path = joinpath(@__DIR__, "build", ".documenter", ".vitepress", "config.mts")
if isfile(config_path)
    config_src = read(config_path, String)
    config_src = replace(config_src, "export default defineConfig({" =>
        "export default defineConfig({\n  ignoreDeadLinks: true,")
    write(config_path, config_src)
end

# Run Vitepress build manually (same as DocumenterVitepress does internally).
@info "Running Vitepress build..."
build_output_path = joinpath(@__DIR__, "build", ".documenter")
package_json = joinpath(@__DIR__, "package.json")
template_json = joinpath(pkgdir(DocumenterVitepress), "template", "package.json")
added_package_json = !isfile(package_json)
added_package_json && cp(template_json, package_json)
try
    cd(@__DIR__) do
        node(; adjust_PATH = true, adjust_LIBPATH = true) do _
            run(`$(npm) install`)
            run(`$(npm) run env -- vitepress build $(build_output_path)`)
        end
    end
finally
    added_package_json && rm(package_json)
end

deploydocs(;
    repo="github.com/JuliaGeodynamics/LaMEM.jl.git",
    target="build",
    branch="gh-pages",
    devbranch="main",
    push_preview=true,
)
