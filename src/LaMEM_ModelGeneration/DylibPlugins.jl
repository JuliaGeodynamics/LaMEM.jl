# Building user-defined phase transitions, written in Julia and compiled into a shared library
# (LaMEM's `dylib_plugin` feature, plugin ABI v3; see doc/src/man/JuliaPlugins.md in LaMEM).
# The plugin is activated in a model with `PhaseTransition(Type="dylib", library=...)` (Materials.jl).

import LaMEM

export build_phase_transition_plugin, LaMEMPlugin_path

# ---------------------------------------------------------------------------------------------
# Building a plugin
# ---------------------------------------------------------------------------------------------

"""
    LaMEMPlugin_path()

Absolute path of `LaMEMPlugin.jl`, the helper module that every phase-transition rule `include`s
(it defines `MarkerView`, `update`, `lamem_pt_wrapper`, ... and the functions LaMEM uses to check the
plugin interface). It is shipped with LaMEM.jl and matches the plugin interface (ABI v3) of the
`LaMEM_jll` this package uses.

A rule file is compiled in a separate Julia process in which LaMEM.jl is not loaded, so it includes
the helper by path, by convention from its own directory:
```julia
include(joinpath(@__DIR__, "LaMEMPlugin.jl"))
using .LaMEMPlugin
```
[`build_phase_transition_plugin`](@ref) copies the file next to the rule file if it is not there yet.
"""
LaMEMPlugin_path() = joinpath(pkgdir(LaMEM), "src", "dylib_plugins", "LaMEMPlugin.jl")

# JuliaC build script shipped with the package (identical to LaMEM's scripts/dylib_plugins/build_plugin.jl)
build_plugin_script() = joinpath(pkgdir(LaMEM), "src", "dylib_plugins", "build_plugin.jl")

# A child julia process, started with this julia. The load path is set to the active project and
# the stdlibs, so that a JULIA_LOAD_PATH of the parent (e.g. the one of Pkg.test, which has no
# @stdlib entry) does not leak into it. The load-path separator is ';' on Windows, ':' elsewhere.
julia_child_cmd(args...) = addenv(`$(Base.julia_cmd()) --startup-file=no $(args)`,
                                  "JULIA_LOAD_PATH" => join(("@", "@stdlib"), Sys.iswindows() ? ";" : ":"))

# Julia environment with JuliaC, created once per session if the user does not provide one
const juliac_env = Ref{String}("")

"""
    env = ensure_juliac_env(julia_env)

Returns a Julia environment with `JuliaC` installed. `julia_env=nothing` uses a temporary environment
that is created (and JuliaC installed into it) at the first call of a session and reused afterwards;
otherwise `julia_env` is a directory or a named environment such as `"@juliac"`, into which JuliaC is
installed if it is not yet there.
"""
function ensure_juliac_env(julia_env)
    if isnothing(julia_env)
        if isempty(juliac_env[]) || !isdir(juliac_env[])
            env = mktempdir()
            println("Installing JuliaC into the temporary environment $env")
            run(julia_child_cmd("--project=$env", "-e", "using Pkg; Pkg.add(\"JuliaC\")"))
            juliac_env[] = env
        end
        return juliac_env[]
    else
        env = String(julia_env)
        if !startswith(env, "@")
            env = abspath(env)
            mkpath(env)
        end
        run(julia_child_cmd("--project=$env", "-e",
                            "using Pkg; haskey(Pkg.project().dependencies, \"JuliaC\") || Pkg.add(\"JuliaC\")"))
        return env
    end
end

"""
    provide_LaMEMPlugin(dir)

Copies the shipped `LaMEMPlugin.jl` to `dir` (the directory of the rule file) if there is none, and
warns if the existing one differs from the shipped one.
"""
function provide_LaMEMPlugin(dir)
    src = LaMEMPlugin_path()
    dst = joinpath(dir, "LaMEMPlugin.jl")
    if !isfile(dst)
        cp(src, dst)
        chmod(dst, 0o644)       # the package directory may be read-only; the copy should not be
        println("Copied LaMEMPlugin.jl to $dst")
    elseif read(dst) != read(src)
        @warn "$dst differs from the LaMEMPlugin.jl shipped with LaMEM.jl ($src). It is used as is; if LaMEM rejects the plugin (ABI or struct layout mismatch), replace it with the shipped version."
    end
    return dst
end

"""
    plugin_library_path(output_dir, name)

Path of the library that `build_plugin.jl` produces for the rule `ptlib_<name>.jl`: JuliaC bundles have
the library in `lib/` on Unix and in `bin/` (next to the other dlls) on Windows.
"""
function plugin_library_path(output_dir, name)
    bundle = joinpath(output_dir, "build_$name")
    if Sys.iswindows()
        return joinpath(bundle, "bin", "libptlib_$name.dll")
    else
        return joinpath(bundle, "lib", "libptlib_$name.$(Sys.isapple() ? "dylib" : "so")")
    end
end

"""
    library = build_phase_transition_plugin(rule_file::String; output_dir=dirname(rule_file), julia_env=nothing)

Compiles the phase-transition rule in `rule_file` with [JuliaC](https://github.com/JuliaLang/JuliaC.jl)
into a LaMEM plugin and returns the absolute path of the library, which is activated in a model with
`add_phasetransition!(model, PhaseTransition(Type="dylib", library=library))`.

The plugin is named after the rule file, without extension and without `ptlib_`: `ptlib_myrule.jl`
gives the bundle directory `<output_dir>/build_myrule`, with the library
`lib/libptlib_myrule.so` (Linux), `lib/libptlib_myrule.dylib` (macOS) or `bin/libptlib_myrule.dll`
(Windows). A bundle left over from an earlier build is removed first. The library needs the other files
of its bundle, so always keep (or move) the whole `build_<name>` directory.

The rule file `include`s the helper module `LaMEMPlugin.jl` from its own directory (see
[`LaMEMPlugin_path`](@ref)). If there is no `LaMEMPlugin.jl` next to `rule_file`, the one shipped with
LaMEM.jl is copied there; an existing one is used as is.

Keyword arguments:
- `output_dir`: directory in which the bundle `build_<name>` is created (default: the directory of `rule_file`)
- `julia_env`: Julia environment used for the build, which must be able to install `JuliaC` (it is
  installed there if needed); a directory or a named environment such as `"@juliac"`. By default, a
  temporary environment is created at the first call of a session and reused for later builds.

The build runs in a separate julia process (the same julia as the current session, which must be
≥ 1.12) and can take a few minutes.

Example
===
```julia
julia> library = build_phase_transition_plugin("ptlib_myrule.jl")
".../build_myrule/lib/libptlib_myrule.so"
julia> add_phasetransition!(model, PhaseTransition(Type="dylib", library=library))
```
"""
function build_phase_transition_plugin(rule_file::AbstractString; output_dir::AbstractString=dirname(abspath(rule_file)), julia_env=nothing)
    VERSION >= v"1.12" || error("Building a phase transition plugin requires julia >= 1.12 (juliac --trim)")

    rule_file = abspath(rule_file)
    isfile(rule_file) || error("rule file $rule_file not found")
    output_dir = abspath(output_dir)
    mkpath(output_dir)

    # plugin name, exactly as build_plugin.jl derives it
    name = replace(splitext(basename(rule_file))[1], "ptlib_" => "")

    provide_LaMEMPlugin(dirname(rule_file))
    env = ensure_juliac_env(julia_env)

    # JuliaC refuses to overwrite an existing bundle
    rm(joinpath(output_dir, "build_$name"); force = true, recursive = true)

    println("Building phase transition plugin $rule_file (this can take a few minutes)")
    run(julia_child_cmd("--project=$env", build_plugin_script(), rule_file, output_dir))

    library = plugin_library_path(output_dir, name)
    isfile(library) || error("Building the plugin did not produce $library")

    return library
end
