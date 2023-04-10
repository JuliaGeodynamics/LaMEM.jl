using Glob

export clean_directory, changefolder

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
        exit()
    end
end
