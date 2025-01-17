#
# START OF PROLOGUE
#
using LaMEM_jll
const HASH_JEN = 0;


function __init__()
    if isfile("libLaMEM.dylib")
        global libLaMEM = joinpath(pwd(),"libMAGEMin.dylib")
        println("Using locally compiled version of libLaMEM.dylib")
    else
        global libLaMEM = LaMEM_jll.libLaMEM
        println("Using libLaMEM.dylib from LaMEM_jll")
    end
end

const PetscInt = Int64
const PetscScalar = Cdouble



#=
const PetscOptions = Ptr{Cvoid}
const PetscViewer = Ptr{Cvoid}
const PetscObject = Ptr{Cvoid}
const Vec = Ptr{Cvoid}
const VecType = Cstring
const Mat = Ptr{Cvoid}
const MatType = Cstring
const KSP = Ptr{Cvoid}
const KSPType = Cstring
const SNES = Ptr{Cvoid}
const SNESType = Cstring
const DM = Ptr{Cvoid}
=#



#
# END OF PROLOGUE
#