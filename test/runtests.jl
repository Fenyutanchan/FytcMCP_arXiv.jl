using FytcMCP_arXiv
using ModelContextProtocol: TextContent
using Test
using JSON3
using EzXML

# Load test fixtures
include("fixtures.jl")

@testset "FytcMCP_arXiv.jl" begin
    include("test_extract_arxiv_id.jl")
    include("test_parse_description.jl")
    include("test_parse_rss_items.jl")
    include("test_json_output.jl")
    include("test_categories.jl")
    include("test_tools.jl")
    include("test_server.jl")
end
