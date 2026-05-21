using FytcMCP_arXiv
using ModelContextProtocol: TextContent
using Test
using JSON3
using EzXML

@testset "FytcMCP_arXiv.jl" begin
    include("test_extract_arXiv_id.jl")
    include("test_parse_description.jl")
    include("test_parse_atom_items.jl")
    include("test_json_output.jl")
    include("test_categories.jl")
    include("test_tools.jl")
    include("test_server.jl")
end
