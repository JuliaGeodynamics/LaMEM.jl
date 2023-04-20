# This contains routines to run LaMEM from julia.
#
# Note: This downloads the BinaryBuilder version of LaMEM, which is not necessarily the latest version of LaMEM 
#       (or the same as the current repository), since we have to manually update the builds.
   
""" 
    run_lamem(ParamFile::String, cores::Int64=1, args:String=""; wait=true)

This starts a LaMEM simulation, for using the parameter file `ParamFile` on `cores` number of cores. 
Optional additional command-line parameters can be specified with `args`.

# Example:
You can call LaMEM with:
```julia
julia> using LaMEM
julia> ParamFile="../../input_models/BuildInSetups/FallingBlock_Multigrid.dat";
julia> run_lamem(ParamFile)
```

Do the same on 2 cores with a command-line argument as:
```julia
julia> ParamFile="../../input_models/BuildInSetups/FallingBlock_Multigrid.dat";
julia> run_lamem(ParamFile, 2, "-nstep_max = 1")
```
"""
function run_lamem(ParamFile::String, cores::Int64=1, args::String=""; wait=true)
        
    if cores==1
        # Run LaMEM on a single core, which does not require a working MPI
        run(`$(LaMEM_jll.LaMEM()) -ParamFile $(ParamFile) $args`);
    else
        # set correct environment
        mpirun = setenv(mpiexec, LaMEM_jll.JLLWrappers.JLLWrappers.LIBPATH_env=>LaMEM_jll.LIBPATH[]);

        # Run LaMEM in parallel
        run(`$(mpirun) -n $cores $(LaMEM_jll.LaMEM_path) -ParamFile $(ParamFile) $args`, wait=wait);
    end

    return nothing
end