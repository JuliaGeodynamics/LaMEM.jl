# This contains routines to run LaMEM from julia.
#
# Note: This downloads the BinaryBuilder version of LaMEM, which is not necessarily the latest version of LaMEM 
#       (or the same as the current repository), since we have to manually update the builds.
   
using Base.Sys

"""
    deactivate_multithreading(cmd)

This deactivates multithreading
"""
function deactivate_multithreading(cmd::Cmd)
    # multithreading of the BLAS libraries that is installed by default with the julia BLAS
    # does not work well. Switch that off:
    cmd = addenv(cmd,"OMP_NUM_THREADS"=>1)
    cmd = addenv(cmd,"VECLIB_MAXIMUM_THREADS"=>1)
    return cmd
end

# Shamelessly stolen from the tests of LBT 
if Sys.iswindows()
    pathsep = ';'
elseif Sys.isapple()
    pathsep = ':'
else
    pathsep = ':'
end

""" 
    run_lamem(ParamFile::String, cores::Int64=1, args:String=""; wait=true, deactivate_multithreads=true)

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
function run_lamem(ParamFile::String, cores::Int64=1, args::String=""; wait=true, deactivate_multithreads=true)
    cores_compute = cores
    if iswindows() && cores>1
        cores_compute=1;
        println("LaMEM_jll does not support parallel runs on windows; using 1 core instead")
    end
    @show cores_compute
    if cores_compute==1
        # Run LaMEM on a single core, which does not require a working MPI
        cmd = `$(LaMEM_jll.LaMEM()) -ParamFile $(ParamFile) $args`
        if deactivate_multithreads
            cmd = deactivate_multithreading(cmd)
        end

        run(cmd, wait=wait);
    else
        # set correct environment
        #mpirun = setenv(mpiexec,  LaMEM_jll.LaMEM().env);
        key = LaMEM_jll.JLLWrappers.JLLWrappers.LIBPATH_env
        mpirun = addenv(mpiexec, key=>join((LaMEM_jll.LIBPATH[], MPI_LIBPATH[]), pathsep));
    

        # create command-line object
        cmd = `$(mpirun) -n $cores_compute $(LaMEM_jll.LaMEM().exec) -ParamFile $(ParamFile) $args`
        if deactivate_multithreads
            cmd = deactivate_multithreading(cmd)
        end

        # Run LaMEM in parallel
        run(cmd, wait=wait);
    end

    return nothing
end