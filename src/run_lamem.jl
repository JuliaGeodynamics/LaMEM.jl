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
    cmd = addenv(cmd,"OPENBLAS_NUM_THREADS"=>1)
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
    add_blas_libs(cmd::Cmd)

PETSc_jll >= 3.25 calls BLAS and LAPACK through libblastrampoline rather than linking
OpenBLAS directly.  A process started from Julia has no backing library registered in
libblastrampoline's slots, so the first BLAS call (in `VecNorm`, say) jumps to a null
pointer.  Point `LBT_DEFAULT_LIBS` at Julia's ILP64 OpenBLAS, which PETSc itself calls,
and at OpenBLAS32's LP64 library, which MUMPS and SuperLU_DIST call internally.
"""
function add_blas_libs(cmd::Cmd)
    shlib_ext = Sys.iswindows() ? "dll" : (Sys.isapple() ? "dylib" : "so")
    ilp64 = Sys.iswindows() ? joinpath(Sys.BINDIR, "libopenblas64_.dll") :
                              joinpath(Sys.BINDIR, "..", "lib", "julia", "libopenblas64_.$(shlib_ext)")
    libs = String[]
    isfile(ilp64) && push!(libs, ilp64)
    push!(libs, OpenBLAS32_jll.libopenblas_path)
    return addenv(cmd, "LBT_DEFAULT_LIBS" => join(libs, ";"))
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
        cmd = add_blas_libs(cmd)

        run(cmd, wait=wait);
    else
        # set correct environment
        key = LaMEM_jll.JLLWrappers.JLLWrappers.LIBPATH_env
        mpirun = addenv(mpiexec, key=>join((LaMEM_jll.LIBPATH[], MPI_LIBPATH[]), pathsep));
    

        # create command-line object  (use LaMEM_path, consistent with run_lamem_save_grid)
        cmd = `$(mpirun) -n $cores_compute $(LaMEM_jll.LaMEM_path) -ParamFile $(ParamFile) $args`
        if deactivate_multithreads
            cmd = deactivate_multithreading(cmd)
        end
        cmd = add_blas_libs(cmd)

        # Run LaMEM in parallel
        run(cmd, wait=wait);
    end

    return nothing
end