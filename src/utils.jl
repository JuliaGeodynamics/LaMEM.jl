

using LaMEM_jll

export remove_popup_messages_mac, show_paths_LaMEM, clean_directory


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