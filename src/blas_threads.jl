# Multithreaded BLAS slows LaMEM down considerably: the linear algebra that julia itself
# performs while setting up/postprocessing a model is small and dominated by threading
# overhead, and the threads compete with the MPI ranks of the LaMEM executable.
# We therefore restrict julia's BLAS to a single thread when the package is loaded.

using LinearAlgebra: BLAS

"""
    set_single_blas_thread()

Sets the number of threads used by julia's BLAS to 1, which is what gives the best
performance when running LaMEM. Called automatically when `LaMEM` is loaded.

It is skipped if the user has expressed an explicit preference, either by setting the
environment variable `LAMEM_SET_BLAS_THREADS=false`, or by setting `OPENBLAS_NUM_THREADS`
or `OMP_NUM_THREADS` before starting julia.

Use [`set_blas_threads`](@ref) to override this from within a session.
"""
function set_single_blas_thread()
    if lowercase(get(ENV, "LAMEM_SET_BLAS_THREADS", "true")) in ("false", "0", "no")
        return nothing
    end
    if haskey(ENV, "OPENBLAS_NUM_THREADS") || haskey(ENV, "OMP_NUM_THREADS")
        # julia already honours these; don't silently override the user
        return nothing
    end
    try
        BLAS.set_num_threads(1)
    catch e
        @warn "LaMEM could not set the number of BLAS threads to 1" exception=e
    end
    return nothing
end

"""
    set_blas_threads(n::Integer)

Sets the number of threads used by julia's BLAS to `n`. `LaMEM` sets this to 1 on load,
as that is usually fastest; use this to go back to multithreaded BLAS:

```julia
julia> using LaMEM
julia> LaMEM.set_blas_threads(Sys.CPU_THREADS)
```
"""
set_blas_threads(n::Integer) = BLAS.set_num_threads(n)

"""
    get_blas_threads()

Returns the number of threads currently used by julia's BLAS.
"""
get_blas_threads() = BLAS.get_num_threads()
