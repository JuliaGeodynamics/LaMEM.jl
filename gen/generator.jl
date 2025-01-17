using Clang.Generators
using Clang.LibClang.Clang_jll
using Pkg
using Pkg.Artifacts
using LaMEM_jll, PETSc_jll, MPICH_jll

cd(@__DIR__)

# Exclude a few things

# headers 
LaMEM_toml = joinpath(dirname(pathof(LaMEM_jll)), "..", "Artifacts.toml")
LaMEM_dir = Pkg.Artifacts.ensure_artifact_installed("LaMEM", LaMEM_toml)

MPICH_toml          = joinpath(dirname(pathof(MPICH_jll)), "..", "Artifacts.toml")       # not for windows
MPICH_dir           = Pkg.Artifacts.ensure_artifact_installed("MPICH", MPICH_toml)

PETSc_toml          = joinpath(dirname(pathof(PETSc_jll)), "..", "Artifacts.toml")       # not for windows
PETSc_dir           = Pkg.Artifacts.ensure_artifact_installed("PETSc", PETSc_toml)

#petsc_include_dir = joinpath(PETSc_dir, "lib/petsc/double_real_Int32/include") |> normpath
petsc_include_dir = joinpath(PETSc_dir, "lib/petsc/double_real_Int32")

lamem_include_dir = joinpath(LaMEM_dir, "include")
mpi_include_dir     = joinpath(MPICH_dir, "include") |> normpath

# wrapper generator options
options = load_options(joinpath(@__DIR__, "generator.toml"))

# add compiler flags, e.g. "-DXXXXXXXXX"
args = get_default_args()
push!(args, "-I$petsc_include_dir")
push!(args, "-I$lamem_include_dir")
push!(args, "-isystem$mpi_include_dir")

# Process all header files in the lamem_include_dir directory:
header_files_mpi   = [joinpath(mpi_include_dir, header) for header in readdir(mpi_include_dir) if endswith(header, ".h")]
header_files_petsc = [joinpath(petsc_include_dir, header) for header in readdir(petsc_include_dir) if endswith(header, ".h")]
header_files_lamem = [joinpath(lamem_include_dir, header) for header in readdir(lamem_include_dir) if endswith(header, ".h")]

#header_files = [header_files_mpi; header_files_petsc; header_files_lamem[1]]

#header_files = detect_headers(lamem_include_dir, args)

header_files = [header_files_lamem[3]]

# create context
ctx = create_context(header_files, args, options)




# run generator
#build!(ctx)