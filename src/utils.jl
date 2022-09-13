

using LaMEM_jll

export remove_popup_messages_mac, show_paths_LaMEM


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


    path_lamem = LaMEM_jll.LaMEM_path

    path_mpi = nothing
    if LaMEM_jll.MPICH_jll.is_available()
        path_mpi = LaMEM_jll.MPICH_jll.mpiexec_path
    elseif LaMEM_jll.MicrosoftMPI_jll.is_available()
        path_mpi = LaMEM_jll.MicrosoftMPI_jll.mpiexec_path
    end
    

    # Print 
    println("LaMEM executables path : $path_lamem")
    println("mpiexec path           : $path_mpi")

    path_lib = LaMEM_jll.__init__();     
    println("Dynamic libraries      : $path_lib")

    println(" ")
    println("Add the following lines to your environment:")
    if Sys.isunix()
        println("export PATH=$(LaMEM_jll.PATH[]):\$PATH")
        println("export DYLD_LIBRARY_PATH=$path_lib")
    elseif Sys.iswindows()
        println("set PATH=$(LaMEM_jll.PATH[]);$(path_lib);%PATH%")
    end

    return nothing
end