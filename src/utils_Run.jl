export remove_popup_messages_mac, show_paths_LaMEM, read_LaMEM_logfile
using MarkdownTables


"""
    remove_popup_messages_mac()

On a Mac with firewall enabled, running LaMEM will result in a popup window that says: "Accept incoming connections" which you should Allow or Deny.
This is a bit annoying, so this julia script fixes that.
Note that you must have administrator rights on your machine as we need to run "sudo"

Run this script from the terminal with
```julia
julia> remove_popup_messages_mac()
```

You need to do this once (every time a new version is installed)

"""
function remove_popup_messages_mac()
    firewall_app = "/usr/libexec/ApplicationFirewall/socketfilterfw"

    # 1) Deactivate firewall
    run(`sudo $firewall_app --setglobalstate off`) 

    # 2) Add MAGEMin executable to firewall 
    exe = LaMEM_jll.LaMEM_path
    run(`sudo $firewall_app --add $(exe)`) 

    # 3) Block incoming connections
    run(`sudo $firewall_app --block $(exe)`) 

    # 4) Activate firewall again
    run(`sudo $firewall_app --setglobalstate on`) 

    return nothing

end


"""
    show_paths_LaMEM()
The downloaded `LaMEM` binaries can also be called from outside julia (directly from the terminal). 
In that case, you will need to set load correct dynamic libraries (such as PETSc) and call the correct binaries.

This function shows this for your system. 
"""
function show_paths_LaMEM()

    path_lamem = LaMEM_jll.PATH[]

    # Print 
    println("LaMEM & mpiexec executables path : $path_lamem")

    path_lib = LaMEM_jll.__init__();     
    println("Dynamic libraries                : $path_lib")

    println(" ")
    println("Add the following lines to your environment:")
    if Sys.isunix()
        println("export PATH=$path_lamem:\$PATH")
        println("export DYLD_LIBRARY_PATH=$path_lib")
    elseif Sys.iswindows()
        println("")
        println("For the normal windows shell, use this:")
        println("set PATH=$(path_lamem);$(path_lib);%PATH%")
       
        println("")
        println("In case you are using the windows PowerShell, use this:")
        println("\$env:Path = \";$(path_lamem);$(path_lib);\" + \$env:Path")
    end

    return nothing
end


"""
This reads a LaMEM logfile (provided it was run with "-log_view") and collects key results from it; 
mostly for scalability tests on HPC machines. It returns a markdown summary
"""
function read_LaMEM_logfile(Filename::String; ID=nothing)
    
    # Read file as vector of strings
    f = open(Filename)
    lines = readlines(f)
    close(f)

    # Extract information from logfile
    Cores       = extract_info_logfile(lines, "Total number of cpu                  :")
    FineGrid    = extract_info_logfile(lines, "Fine grid cells [nx, ny, nz]         :")
    CoarseGrid  = extract_info_logfile(lines, "Global coarse grid [nx,ny,nz] :")
    Levels      = parse(Int64,extract_info_logfile(lines, "Number of multigrid levels    :"))

    TotalTime_s  = extract_info_logfile(lines, "Time (sec):", LaMEM=false)
    CoarseTime_s = extract_info_logfile(lines, "MGSmooth Level 0", LaMEM=false, entry=3)
    Iter         = Int64(extract_info_logfile(lines, "SNESSolve", LaMEM=false, entry=1))


    # Retrieve memory usage if we have system with slurm (use seff)
    if isnothing(ID)
        ID = split(split(Filename,".")[1],"_")[end]
    end
    lines_mem = execute_command("seff $ID"); # run code
    if !isnothing(lines_mem)
        Memory  = extract_info_logfile(lines, "Memory Utilized:", LaMEM=false, entry=1)
    else
        Memory = "-"
    end

    # print as Markdown table
    table = (; FineGrid, Cores, CoarseGrid, Levels, Iter, TotalTime_s, CoarseTime_s, Memory, Filename) 
    println(markdown_table([table], String))

    return lines
end

add_str(str, keyword, pad) = str*"| $(rpad(keyword,pad))"

"""

    value = extract_info_logfile(lines, keyword::String; entry=1, LaMEM=true)

Internal function to extract information from the logfile

Note that the LaMEM keywords should contain ":" at the end, while the PETSc keywords should not, but we have to indicate the entry number for the PETSc keywords.
Example LaMEM keyword:
```julia
julia> val = extract_info_logfile(lines, "Fine grid cells [nx, ny, nz]         :")
"[512, 256, 256]"
```

Example PETSc keyword:
```julia
julia> coarse_grid_solve = extract_info_logfile(lines, "MGSmooth Level 0", LaMEM=false, entry=3)
9.9174
```
"""
function extract_info_logfile(lines, keyword::String; entry=1, LaMEM=true)
    # find the line with the keyword
    idx = findfirst(x->occursin(keyword,x), lines)
    if idx==nothing
        return "-"
    end

    # extract the value
    line_no_keyword = strip(split(lines[idx],keyword)[end])
    if LaMEM
        # LaMEM output is simply everything after the keyword
        value = line_no_keyword
    else
        # PETSc output usually is a table; transfer this to a Float64
        values_vec = split(line_no_keyword," ")
        value = values_vec[entry]
        value = parse(Float64,value)
    end
    
    return value
end


"""
    str = execute_command(command="ls")    

Executes a command-line code and returns the output as a string
"""
function execute_command(command="ls")
    
    # execute command 
    io = IOBuffer();
    cmd = pipeline(`$command`; stdout=io, stderr=devnull);

    str = nothing
    try 
        run(cmd);
        str = String(take!(io))
        str = split(str,"\n")
    catch
        str = nothing
    end

    return str
end




