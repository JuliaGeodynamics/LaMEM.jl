# Installation on HPC systems

Installing LaMEM on high performance computer (HPC) systems can be complicated, because you will have to compile PETSc with the correct dependencies for that system. 
The reason is that HPC systems use MPI versions that are specifically tailored/compiled for that system. 

> Warning: the explanation below is still somewhat experimental and may not work on your system
> The best approach of running LaMEM on large HPC systems remains to install the correct version of PETSc using the locally recommended MPI libraries and install the correct version of LaMEM with that. You can still save the input setup to file, for the correct number or processors using LaMEM.jl. The locally generated `*.dat` file will still work.

Luckily there is a solution thanks to the great work of `@eschnett` and colleagues, who developed [MPITrampoline](https://github.com/eschnett/MPItrampoline) which is an intermediate layer between the HPC-system-specific MPI libraries and the precompiled `LaMEM` binaries. 

It essentially consists of two steps: 
    1) compile a small package ([MPIwrapper](https://github.com/eschnett/MPIwrapper)) 
    2) make sure that you download the version of `LaMEM` that was compiled versus `MPItrampoline`.

Here step-by-step instructions (for Linux, as that is what essentially all HPC systems use):


* Download [MPIwrapper](https://github.com/eschnett/MPIwrapper): 
```bash
git clone https://github.com/eschnett/MPIwrapper.git 
cd MPIwrapper
```

* Install it after making sure that `mpiexec` points to the one you want (you may have to load some modules, depending on your system):
```bash
cmake -S . -B build -DMPIEXEC_EXECUTABLE=/full/path/to/mpiexec -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=$HOME/mpiwrapper
cmake --build build
cmake --install build
```
> [!IMPORTANT]  
> You need to specify the full path to `mpiexec` (or equivalent) and not just the name. If you don't know that, you can determine this with
> `which mpiexec`
 
At this stage, `MPItrampoline` is installed in `$HOME/mpiwrapper`

* Set the correct wrappers:
```
export MPITRAMPOLINE_LIB=$HOME/mpiwrapper/lib64/libmpiwrapper.so
export MPITRAMPOLINE_MPIEXEC=$HOME/MPIwrapper/mpiwrapper/bin/mpiwrapperexec 
```
Depending on the system it may be called `lib` instead of `lib64` (check!).

* Start julia and install a compatible version of `MPItrampoline_jll`
`LaMEM_jll` and `PETSc_jll` are compiled versus `MPItrampoline_jll`, and they need MPI-4 functionality (such as `MPI_Allreduce_c`) that older versions do not provide. 
You therefore need `MPItrampoline_jll` version `5.5.3` or newer (the same version range that is used to build `PETSc_jll`, see [here](https://github.com/JuliaPackaging/Yggdrasil/blob/master/L/LaMEM/build_tarballs.jl)):
```julia
julia
julia> ]
pkg>add MPItrampoline_jll@5.5.3
```
> [!WARNING]
> If you use an older `MPItrampoline_jll` (e.g. `5.2.1`, which this page used to recommend), preparing or running a model fails with an error such as
> `symbol lookup error: .../libpetsc_double_real_Int32_double_real_Int32.so.3.22: undefined symbol: MPI_Allreduce_c`.
> Check which version you have with `]status MPItrampoline_jll` and update it if needed.
> Also make sure that `MPIwrapper` (see above) was compiled against an MPI library that is MPI-4 compliant (e.g., OpenMPI 5 or MPICH 4), as `MPItrampoline` forwards the calls to it.


* Install the `MPI` and `MPIPreferences` packages:
```julia
julia
julia> ]
pkg>add MPI, MPIPreferences
```

* Set the preference to use `MPItrampoline`
```julia
julia> using MPIPreferences; MPIPreferences.use_jll_binary("MPItrampoline_jll")
┌ Info: MPIPreferences unchanged
└   binary = "MPItrampoline_jll"
```

* Load `MPI` and verify it is the correct one
```julia
julia> using MPI
julia> MPI.Get_library_version()
"MPIwrapper 2.10.3, using MPIABI 2.9.0, wrapping:\nOpen MPI v4.1.4, package: Open MPI boris@Pluton Distribution, ident: 4.1.4, repo rev: v4.1.4, May 26, 2022"
```
After this, restart julia (this only needs to be done once, next time all is fine).

If you want you can run a test case with:
```julia
julia> using MPI
julia> mpiexec(cmd -> run(`$cmd -n 3 echo hello world`));
hello world
hello world
hello world
```

* Now load `LaMEM` and check that it uses the `mpitrampoline` version:
```julia
julia> using MPI,LaMEM
julia> LaMEM.LaMEM_jll.host_platform
Linux x86_64 {cxxstring_abi=cxx11, julia_version=1.8.1, libc=glibc, libgfortran_version=5.0.0, mpi=mpitrampoline}
```

At this stage the precompiled version of `LaMEM` should be useable on that system.

* Run LaMEM
you can run LaMEM on 2 cores, for example with [this](https://github.com/UniMainzGeo/LaMEM/blob/master/input_models/ScalingTests/FallingSpheres.dat) example file, with:
```julia
julia> using LaMEM
julia> run_lamem("FallingSpheres.dat", 2)
```
 
