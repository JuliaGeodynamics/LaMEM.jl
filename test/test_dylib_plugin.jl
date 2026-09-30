using Test, Base.Sys

# Tests LaMEM's dylib_plugin feature: a user-defined phase-transition rule,
# written in Julia and compiled to a shared library with JuliaC.jl, loaded
# by LaMEM at runtime via `dylib_plugin = <path>` / `phase_transitions = dylib`
# in the .dat file (see LaMEM's src/dylib_plugins.h).
#
# Not yet supported on Windows (dylib_plugin fails there with a clear error),
# and needs Julia >= 1.12 for `juliac --trim` to build the plugin bundle.
# Both cases are skipped, not failed, so this test degrades gracefully on
# platforms/versions that cannot build or run the plugin yet.

pkg_dir = pkgdir(LaMEM)
plugin_dir = joinpath(pkg_dir, "test", "dylib_plugin_test")

@testset "dylib_plugin" begin
    if Sys.iswindows()
        @test_skip "dylib_plugin is not yet supported on Windows"
    elseif VERSION < v"1.12"
        @test_skip "building the plugin needs Julia >= 1.12 (juliac --trim)"
    else
        # Build the plugin bundle with JuliaC.jl, in a temporary, isolated
        # Julia environment so this does not touch the user's own project.
        build_env = mktempdir()
        try
            run(`$(Base.julia_cmd()) --startup-file=no --project=$build_env -e 'using Pkg; Pkg.add("JuliaC")'`)
        catch e
            @warn "could not install JuliaC.jl to build the plugin" exception = e
            @test_skip "could not install JuliaC.jl to build the plugin"
        else
            rule_file = joinpath(plugin_dir, "ptlib_constant.jl")
            build_script = joinpath(plugin_dir, "build_plugin.jl")
            run(`$(Base.julia_cmd()) --startup-file=no --project=$build_env $build_script $rule_file $plugin_dir`)

            dlext = Sys.isapple() ? "dylib" : "so"
            bundle_path = joinpath(plugin_dir, "build_constant", "lib", "libptlib_constant.$dlext")
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
end
