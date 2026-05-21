@testset "parse_description" begin
    @testset "typical new submission" begin
        desc = "arXiv:2605.10001v1 Announce Type: new \nAbstract: This is the abstract of the first test paper."
        result = FytcMCP_arXiv.parse_description(desc)
        @test result["announce_type"] == "new"
        @test result["abstract"] == "This is the abstract of the first test paper."
    end

    @testset "cross-listed paper" begin
        desc = "arXiv:2605.10002v1 Announce Type: cross \nAbstract: This is the cross-listed paper abstract."
        result = FytcMCP_arXiv.parse_description(desc)
        @test result["announce_type"] == "cross"
        @test result["abstract"] == "This is the cross-listed paper abstract."
    end

    @testset "replaced paper" begin
        desc = "arXiv:2605.10004v2 Announce Type: rep \nAbstract: Updated abstract."
        result = FytcMCP_arXiv.parse_description(desc)
        @test result["announce_type"] == "rep"
        @test result["abstract"] == "Updated abstract."
    end

    @testset "description without announce type" begin
        desc = "arXiv:2605.99999v1 Some text without proper format"
        result = FytcMCP_arXiv.parse_description(desc)
        @test !haskey(result, "announce_type")
        @test !haskey(result, "abstract")
    end

    @testset "empty description" begin
        result = FytcMCP_arXiv.parse_description("")
        @test isempty(result)
    end

    @testset "abstract with special characters" begin
        desc = "arXiv:2605.10001v1 Announce Type: new \nAbstract: Contains \$\\alpha\$ and \$\\beta\$ symbols."
        result = FytcMCP_arXiv.parse_description(desc)
        @test occursin("\\alpha", result["abstract"])
        @test occursin("\\beta", result["abstract"])
    end

    @testset "abstract is stripped of whitespace" begin
        desc = "arXiv:2605.10001v1 Announce Type: new \nAbstract:   Spaced out abstract.   \n"
        result = FytcMCP_arXiv.parse_description(desc)
        @test result["abstract"] == "Spaced out abstract."
    end
end
