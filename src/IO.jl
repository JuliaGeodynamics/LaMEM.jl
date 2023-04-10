module IO
# this contains I/O routines of LaMEM, which don't require LaMEM_jll

include("read_timestep.jl")
export Read_LaMEM_PVTR_File, Read_LaMEM_PVTS_File, field_names, readPVD, Read_LaMEM_PVTU_File

include("utils_IO.jl")
export clean_directory, changefolder


end