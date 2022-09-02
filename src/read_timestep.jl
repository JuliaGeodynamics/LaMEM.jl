# The routines specified in this module read a LaMEM timestep and return 2D or 3D
# Scalar or Vector Data to julia, for further quantitative analysis
# 
                  
# Make these routines easily available outside the module:
using GeophysicalModelGenerator: CartData, XYZGrid
using PythonCall
using Glob

export Read_VTR_File, clean_directory, field_names


function vtkXMLPRectilinearGridReader(FileName)
  reader1  = pyvtk.vtkXMLPRectilinearGridReader()
  reader1.SetFileName(FileName)
  reader1.Update()
  data    = reader1.GetOutput()
  return data
end

""" 
    Extracts a 3D data field from a pVTR data structure
Usage:
    output = ReadField_3D_pVTR(data, FieldName::String)

Input:
-   `data`:       Data structure obtained with Read_VTR_File
-   `FieldName`:  Exact name of the field as specified in the *.vtr file
    
Output:
- `data_field`, `x`,`y`,`z`:   3D field with data, as well as 1D vectors with x,y,z coordinates
                               `data_field` is a tuple of size 1, or 3 depending on whether it is a scalar or vector field
    
"""
function ReadField_3D_pVTR(data, FieldName)
    
    x               =   data.GetXCoordinates();
    y               =   data.GetYCoordinates();
    z               =   data.GetZCoordinates();
   
    nx              =   pyconvert(Int, x.GetSize());
    ny              =   pyconvert(Int, y.GetSize());
    nz              =   pyconvert(Int, z.GetSize());
    
    data_Field      =   pyconvert(Array, data.GetPointData().GetArray(FieldName));
    if size(data_Field,2) == 1
        data_Field  =   reshape(data_Field     ,(nx,ny,nz));
        data_Tuple  =   (data_Field, )
    elseif size(data_Field,2) == 3
        Vx          =   reshape(data_Field[:,1],(nx,ny,nz));
        Vy          =   reshape(data_Field[:,2],(nx,ny,nz));
        Vz          =   reshape(data_Field[:,3],(nx,ny,nz));
        data_Tuple  =   ((Vx,Vy,Vz),)
    elseif size(data_Field,2) == 9
        xx          =   reshape(data_Field[:,1],(nx,ny,nz));
        xy          =   reshape(data_Field[:,2],(nx,ny,nz));
        xz          =   reshape(data_Field[:,3],(nx,ny,nz));
        yx          =   reshape(data_Field[:,4],(nx,ny,nz));
        yy          =   reshape(data_Field[:,5],(nx,ny,nz));
        yz          =   reshape(data_Field[:,6],(nx,ny,nz));
        zx          =   reshape(data_Field[:,7],(nx,ny,nz));
        zy          =   reshape(data_Field[:,8],(nx,ny,nz));
        zz          =   reshape(data_Field[:,9],(nx,ny,nz));
        
        data_Tuple  =   ((xx,xy,xz,yx,yy,yz,zx,zy,zz),)
    else
        error("Not yet implemented for this size $(size(data_Field,2))")
    end
    name = filter(x -> !isspace(x), FieldName)  # remove white spaces

    id   = findfirst("[", name)
    if !isempty(id)
        name = name[1:id[1]-1]      # strip out "[" signs
    end
    data_out = NamedTuple{(Symbol(name),)}(data_Tuple,);

    return data_out
end

"""
    returns the names of all fields stored in the vtr file
"""
function field_names(data)
    names = [];
    pdata = data.GetPointData()

    num = pyconvert(Int,pdata.GetNumberOfArrays())
    for i=1:num
        names = [names; pyconvert(String,pdata.GetArrayName(i-1))]
    end

    return names;
end

"""
    names = field_names(DirName, FileName)

Returns the names of all fields stored in the vtr file in the directory `Directory` and file `FileName`.
"""
function field_names(DirName, FileName)
    CurDir = pwd();

    # change to directory
    cd(DirName)

    # read data from parallel rectilinear grid
    data = vtkXMLPRectilinearGridReader(FileName);      # this is how it should be done within modules
    cd(CurDir)

    # Fields stored in this data file:     
    names = field_names(data);

    return names;
end


"""
    data = Read_VTR_File(DirName, FileName; field=nothing)
Reads a 3D LaMEM timestep (from pVTR file)

Usage:
        
Input:
    - `DirName` :   Name of timestep directory (e.g., `Timestep_00000001_1.10000000e-01`)
    - `FileName`:   Filename (e.g., `Subduction2D_direct.pvtr`)    
    - `field`:      Name of the field ypu want to extract. If not specified, all will be read

Output:
    - `data`    :   data structure containing the full content of the VTR file
"""
function Read_VTR_File(DirName, FileName; field=nothing)
    CurDir = pwd();

    # change to directory
    cd(DirName)

    # read data from parallel rectilinear grid
    data = vtkXMLPRectilinearGridReader(FileName);      # this is how it should be done within modules
    cd(CurDir)

    # Fields stored in this data file:     
    names = field_names(data);

    if isnothing(field)
        # read all data in the file
        data_fields = NamedTuple();
        for FieldName in names
            data_fields = merge(data_fields,ReadField_3D_pVTR(data, FieldName))
        end

    else
        # read just a single data set
        ind = findall(contains.(field, names))
        # check that it exists
        if isempty(ind)
            error("the field $field does not exist in the data file")
        else
            data_fields = ReadField_3D_pVTR(data, field)
        end
    end

    # Read coordinates
    x               =   pyconvert(Array,data.GetXCoordinates());
    y               =   pyconvert(Array,data.GetYCoordinates());
    z               =   pyconvert(Array,data.GetZCoordinates());

    X,Y,Z = XYZGrid(x,y,z)
    data_output     =   CartData(X,Y,Z, data_fields)
    return data_output   
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

    #timestep directories
    for f in glob("Timestep*")
        rm(f, recursive=true, force=true)
    end


    cd(CurDir)

end