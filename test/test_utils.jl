# Helpers to keep test output directories from interfering with each other.
#
# Several tests write into the same `out_dir` (e.g. "example_1"). If a directory is left
# behind by an earlier run, LaMEM writes its new timesteps next to the old ones and the
# `*.pvd` file ends up describing both, so `read_LaMEM_timestep(..., last=true)` can pick
# up a timestep of the previous run. On the CI this never happens (clean checkout), but
# locally -- in particular on windows, where `runtests.jl` skips the final
# `clean_directory` -- the leftovers survive from one test session to the next.

"""
    rm_dir(dir)

Removes `dir` if it exists. On windows a directory cannot be removed while a file in it is
still open or while it is the current directory of a process, which shows up as a
permission error; retry a few times before giving up, and warn rather than fail.
"""
function rm_dir(dir)
    (isempty(dir) || !ispath(dir)) && return nothing
    for attempt in 1:5
        try
            rm(dir, force=true, recursive=true)
            return nothing
        catch e
            attempt == 5 && (@warn "could not remove test directory $dir" exception=e; return nothing)
            sleep(0.2*attempt)   # give windows time to release the handles
        end
    end
    return nothing
end

"""
    clean_output_dir(model)

Removes the output directory of `model`, so that the model starts from a clean state.
"""
clean_output_dir(model) = rm_dir(model.Output.out_dir)
