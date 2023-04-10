# This contains routines to saving processor partitioning file to run LaMEM from julia.
# Returns the name of the processor partitioning file
#
# Note: This downloads the BinaryBuilder version of LaMEM, which is not necessarily the latest version of LaMEM 
#       (or the same as the current repository), since we have to manually update the builds.
   

function run_lamem_with_log(ParamFile::String, cores::Int64=1, args::String="")
        
	currdir = pwd()
	cd(dirname(abspath(ParamFile)))
	ParamFile = splitdir(ParamFile)[2]
	# set correct environment
	mpirun = setenv(mpiexec, LaMEM_jll.JLLWrappers.JLLWrappers.LIBPATH_env=>LaMEM_jll.LIBPATH[]);
	# Call LaMEM to generate Processor Partitioning file and output
	out = Pipe()
	err = Pipe()
	run(pipeline(ignorestatus(`$(mpirun) -n $cores $(LaMEM_jll.LaMEM_path) -ParamFile $(ParamFile) $args`),stdout=out));
	close(out.in)
	(
	stdout = String(read(out))
	 )
	 cd(currdir)
	 return stdout
end

function JuliaStringToArray(input)


    arr = split(input,"\n")
	return arr
end

function get_line_containing(stringarray::Vector{SubString{String}}, lookfor::String)


	for line in stringarray
		   if contains(line, lookfor)
		   foundline=line
		   return foundline
		   end
	end
end

""" 
    run_lamem_save_grid(ParamFile::String, cores::Int64=1)
This calls LaMEM simulation, for using the parameter file `ParamFile` 
and creates processor paritioning file "ProcessorPartitioning_`cores`cpu_X.Y.Z.bin" for `cores` number of cores. 
# Example:
The first step is to ensure that `LaMEM_jll` is installed on your system. You only need to do this once, or once LaMEM_jll is updated. 
```julia
julia> import Pkg
julia> Pkg.add("LaMEM_jll")
```
Next you can call LaMEM with:
```julia
julia> ParamFile="../../input_models/BuildInSetups/FallingBlock_Multigrid.dat";
julia> run_lamem_save_grid(ParamFile, 2)
```
"""
function run_lamem_save_grid(ParamFile::String, cores::Int64=1)
	if cores==1	
		return print("No partitioning file required for 1 core model setup \n")	
	end

	ParamFile    = abspath(ParamFile)
	logoutput    = run_lamem_with_log(ParamFile, cores,"-mode save_grid" )
	arr          = JuliaStringToArray(logoutput)
	foundline    = get_line_containing(arr,"Processor grid  [nx, ny, nz]         : ")
	foundline    = join(map(x -> isspace(foundline[x]) ? "" : foundline[x], 1:length(foundline)))
	sprtlftbrkt  = split(foundline,"[")
	sprtrghtbrkt = split(sprtlftbrkt[3],"]")
	separatecoma = split(sprtrghtbrkt[1],",")
	procnumbers  = parse.(Int, separatecoma)
	Procpartname = "ProcessorPartitioning_$(cores)cpu_$(procnumbers[1]).$(procnumbers[2]).$(procnumbers[3]).bin" 
	if isfile(joinpath((splitdir(ParamFile)[1]),Procpartname))
		return Procpartname
	else
	return Nothing
	end
end
