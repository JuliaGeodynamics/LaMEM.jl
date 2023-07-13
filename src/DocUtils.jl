# Auto-generate comments from the documentation

using DocStringExtensions
export get_doc
"""
    help_info::String = get_doc(structure, field::Symbol) 
This returns a string with the documentation for a parameter `field` that is within the `structure`. 
Note that this structure must be a help structure of the current one.
"""
function get_doc(structure, field::Symbol) 
    alldocs       =   Docs.meta(LaMEM.LaMEM_Model);
    
    var           =   eval(Meta.parse("Docs.@var($structure)"))
    fields_local  =   alldocs[var].docs[Union{}].data[:fields]
    str = fields_local[field]

    # Add comment to next line (if required)
    str = replace(str, "\n" => "\n #")

    # remove the # at the end of the string
    if str[end]=='#'
        str = str[1:end-1]
    end

    return str
end