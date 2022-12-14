# Installation

Installing LaMEM can simply be done through the package manager:
```julia
julia>]
pkg>add LaMEM
```
which will download the binaries along with PETSc and mpiexec for your system.

You can test if it works on your machine with
```julia
pkg> test LaMEM
```

If you also want to read LaMEM output files back to julia, you need to install the `PythonCall` package:
```julia
julia> ]
pkg> add PythonCall
```

### Running LaMEM from julia
Running LaMEM from within julia can be done with the `run_lamem` function:

```@docs
LaMEM.run_lamem
```




### Running LaMEM from outside julia
If you, for some reason, do not want to run LaMEM through julia but instead directly from the terminal or powershell, you will have to add the required dynamic libraries and executables.
Do this with:
```@docs
LaMEM.show_paths_LaMEM
```