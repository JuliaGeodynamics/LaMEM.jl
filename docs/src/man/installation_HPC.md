# Installation on HPC systems

Installing LaMEM on high performance computer (HPC) systems can be complicated, because you will have to compile PETSc with the correct dependencies for that system. 
The reason is that HPC systems use MPI versions that are specifically tailored/compiled for that system. 

Luckily there is a solution thanks to the great work of `@eschnett` and colleagues, who developed [MPITrampoline](https://github.com/eschnett/MPItrampoline) which is an intermediate layer between the HPC-system-specific MPI libraries and the precompiled `LaMEM` binaries. 

It essentially consists of two steps: 
    1) compile a small package ([MPIwrapper](https://github.com/eschnett/MPIwrapper)) 
    2) make sure that you download the version of `MAGEMin` that was compiled versus `MPItrampoline`.

Here step-by-step instructions (for Linux, as that is what essentially all HPC systems use):


* Download [MPIwrapper](https://github.com/eschnett/MPIwrapper): 
```bash
$git clone https://github.com/eschnett/MPIwrapper.git 
$cd MPIwrapper
```

* Install it after making sure that `mpiexec` points to the one you want (you may have to load some modules, depending on your system):
```bash
$cmake -S . -B build -DMPIEXEC_EXECUTABLE=mpiexec -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=$HOME/mpiwrapper
$cmake --build build
$cmake --install build
```
At this stage, `MPItrampoline` is installed in `$HOME/mpiwrapper`

* Set the correct wrapper:
```
$export MPITRAMPOLINE_LIB=$HOME/mpiwrapper/lib64/libmpiwrapper.so
```
Depending on the system it may be called `lib` instead of `lib64` (check!).

* Start julia and install the `MPI` and `MPIPreferences` packages:
```julia
$julia
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

* Now load `LaMEM` and check that it uses the `mpitrampoline` version:
```julia
julia> using MPI,LaMEM
julia> LaMEM.LaMEM_jll.host_platform
Linux x86_64 {cxxstring_abi=cxx11, julia_version=1.8.1, libc=glibc, libgfortran_version=5.0.0, mpi=mpitrampoline}
```

At this stage the precompiled version of `LaMEM` should be useable on that system.