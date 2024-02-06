using Glob, DelimitedFiles

export clean_directory, changefolder, read_phase_diagram

""" 
    clean_directory(DirName)

Removes all LaMEM timesteps & `*.pvd` files from the directory `DirName`

"""
function clean_directory(DirName="./")
    
    CurDir = pwd();

    # change to directory
    cd(DirName)

    # pvd files
    for f in glob("*.pvd")
         rm(f)
    end

    # vts files
    for f in glob("*.vts")
        rm(f)
    end

    #timestep directories
    for f in glob("Timestep*")
        rm(f, recursive=true, force=true)
    end


    cd(CurDir)
end


"""
    changefolder()

Starts a GUI on Windowss or Mac machines, which allows you to change our working directory
"""
function changefolder()
    if Sys.iswindows() 
        command = """
        Function Get-Folder(\$initialDirectory) {
            [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

            \$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
            \$foldername.Description = "Select a folder"
            \$foldername.rootfolder = "MyComputer"

            if(\$foldername.ShowDialog() -eq "OK")
            {
                \$folder += \$foldername.SelectedPath
            }
            return \$folder
        }

        Get-Folder
        """
        cd(chomp(read(`powershell -Command $command`, String)))
        println(pwd())
    elseif Sys.isapple() 
        command = """
        try
            set af to (choose folder with prompt "Folder?")
            set result to POSIX path of af
        on error
            beep
            set result to "$(pwd())"
        end
        result
        """
        cd(chomp(read(`osascript -e $command`, String)))
        println(pwd())
    else
        error("This only works on windows and mac")
    end
end

"""
    out = read_phase_diagram(name::String)

Reads a phase diagram from a file `name` and returns a NamedTuple with temperature `T`, pressure `P`, melt density `ρ_melt`, solid density `ρ_solid`, density `ρ` and melt fraction `ϕ`
"""
function read_phase_diagram(name::String)

    f = open(name)

    # Read dimensions
    for i = 1:49; readline(f); end
    minT = parse(Float64,   readline(f))
    ΔT   = parse(Float64,   readline(f))
    nT   = parse(Int64,     readline(f))
    minP = parse(Float64,   readline(f))
    ΔP   = parse(Float64,   readline(f))
    nP   = parse(Int64,     readline(f))
    close(f)
    
    data = readdlm(name, skipstart=55);     # read numerical data

    # reshape
    ρ_melt  = reshape(data[:,1],(nT,nP));
    ϕ       = reshape(data[:,2],(nT,nP));
    ρ_solid = reshape(data[:,3],(nT,nP));
    T_K     = reshape(data[:,4],(nT,nP));
    P_bar   = reshape(data[:,5],(nT,nP));
    ρ       = ρ_melt.*ϕ .+ ρ_solid.*(1.0 .- ϕ);

    
    return (;T_K,P_bar,ρ_melt,ρ_solid,ϕ, ρ)
end

