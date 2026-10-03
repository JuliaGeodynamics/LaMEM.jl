using Test, Base.Sys

# Tests LaMEM's dylib_plugin feature: a user-defined phase-transition rule,
# written in Julia and compiled to a shared library with JuliaC.jl, loaded
# by LaMEM at runtime via `dylib_plugin = <path>` / `phase_transitions = dylib`
# in the .dat file (see LaMEM's src/dylib_plugins.h).
#
# Building the plugin needs Julia >= 1.12 (`juliac --trim`); older versions
# skip. Everything else is a hard failure: the plugin is supported on Linux,
# macOS and Windows.

pkg_dir = pkgdir(LaMEM)
plugin_dir = joinpath(pkg_dir, "test", "dylib_plugin_test")

# Pkg.test runs the tests with JULIA_LOAD_PATH="@:<test env>", which has no
# @stdlib entry, so a child process started with its own --project cannot
# even `using Pkg`. Give the children a load path of their project + stdlibs.
# (the load-path separator is ';' on Windows, ':' elsewhere)
julia_cmd(args...) = addenv(`$(Base.julia_cmd()) --startup-file=no $(args)`,
                            "JULIA_LOAD_PATH" => join(("@", "@stdlib"), Sys.iswindows() ? ";" : ":"))

@testset "dylib_plugin" begin
    if VERSION < v"1.12"
        @test_skip "building the plugin needs Julia >= 1.12 (juliac --trim)"
    else
        # Build the plugin bundle with JuliaC.jl in a temporary, isolated
        # Julia environment so this does not touch the user's own project.
        build_env = mktempdir()
        run(julia_cmd("--project=$build_env", "-e", "using Pkg; Pkg.add(\"JuliaC\")"))

        rule_file = joinpath(plugin_dir, "ptlib_constant.jl")
        build_script = joinpath(plugin_dir, "build_plugin.jl")
        run(julia_cmd("--project=$build_env", build_script, rule_file, plugin_dir))

        # JuliaC's bundles are <out>/lib/*.{so,dylib} on Unix, but flat under
        # <out>/bin/ on Windows.
        bundle_path = if Sys.iswindows()
            joinpath(plugin_dir, "build_constant", "bin", "libptlib_constant.dll")
        else
            joinpath(plugin_dir, "build_constant", "lib", "libptlib_constant.$(Sys.isapple() ? "dylib" : "so")")
        end
        @test isfile(bundle_path)

        ParamFile = joinpath(plugin_dir, "PT0_only_plugin.dat")
        logfile = joinpath(plugin_dir, "dylib_plugin_test.log")

        out = run_lamem(ParamFile, 1, "-dylib_plugin $bundle_path"; logfile = logfile)
        @test isnothing(out)

        # The plugin reimplements the .dat's built-in "Constant" phase
        # transition; on this setup it flips a known number of markers
        # from phase 2 to phase 3 at the very first step. Checking that
        # count (rather than just that LaMEM exits cleanly) confirms the
        # plugin library was actually loaded and its rule actually ran,
        # not just that LaMEM ignored the option.
        @test isfile(logfile)
        log = read(logfile, String)
        @test occursin("Dylib plugin", log)
        m = match(r"Dylib plugin\s*:\s*(\d+) marker\(s\) changed phase", log)
        @test !isnothing(m)
        if !isnothing(m)
            @test parse(Int, m.captures[1]) == 27512
        end
    end
end
