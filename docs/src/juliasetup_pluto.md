# Using Pluto or Jupyter notebooks

#### Pluto
You can also run LaMEM directly using Pluto notebooks:
```julia
julia> using Pluto
julia> Pluto.run()
```
we have provided examples in the `notebooks` directory of the `LaMEM.jl` package.


#### Jupyter
And for the ones of you that are more used to Jupyter notebooks, we also provide an example. Note that this will require you to install the required packages in julia first and use the `IJulia` package:

```julia
julia> using IJulia
julia> notebook()
```