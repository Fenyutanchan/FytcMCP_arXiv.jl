@testset "MCP Tools" begin
    @testset "tool definitions" begin
        tools = FytcMCP_arXiv.server.tools
        tool_names = [t.name for t in tools]

        @test "fetch_daily_new_submissions" in tool_names
        @test "fetch_daily_cross_listed" in tool_names
        @test "fetch_all_daily_updates" in tool_names
        @test "get_arxiv_paper" in tool_names
        @test "list_arxiv_categories" in tool_names
        @test length(tools) == 5
    end

    @testset "tool parameter definitions" begin
        tools = FytcMCP_arXiv.server.tools
        tool_dict = Dict(t.name => t for t in tools)

        @testset "fetch_daily_new_submissions params" begin
            t = tool_dict["fetch_daily_new_submissions"]
            param_names = [p.name for p in t.parameters]
            @test "category" in param_names
            @test "max_abstract_length" in param_names
        end

        @testset "get_arxiv_paper params" begin
            t = tool_dict["get_arxiv_paper"]
            param_names = [p.name for p in t.parameters]
            @test "arxiv_id" in param_names
            @test "category" in param_names
        end

        @testset "list_arxiv_categories params" begin
            t = tool_dict["list_arxiv_categories"]
            param_names = [p.name for p in t.parameters]
            @test "filter" in param_names
        end
    end

    @testset "list_arxiv_categories handler (live)" begin
        t = only(filter(t -> t.name == "list_arxiv_categories", FytcMCP_arXiv.server.tools))

        @testset "without filter" begin
            result = t.handler(Dict{String, Any}())
            @test isa(result, TextContent)
            data = JSON3.read(result.text)
            @test data["count"] > 0
            @test haskey(data, "categories")
            @test haskey(data["categories"], "hep-ph")
        end

        @testset "with filter" begin
            result = t.handler(Dict{String, Any}("filter" => "hep"))
            data = JSON3.read(result.text)
            @test data["count"] > 0
            @test data["filter"] == "hep"
            for (group, subs) in pairs(data["categories"])
                for s in subs
                    @test occursin("hep", lowercase(s))
                end
            end
        end

        @testset "filter with no matches" begin
            result = t.handler(Dict{String, Any}("filter" => "zzzznonexistent"))
            data = JSON3.read(result.text)
            @test data["count"] == 0
        end
    end

    @testset "fetch_daily_new_submissions handler (live)" begin
        t = only(filter(t -> t.name == "fetch_daily_new_submissions", FytcMCP_arXiv.server.tools))
        result = t.handler(Dict{String, Any}("category" => "hep-ph"))
        @test isa(result, TextContent)
        data = JSON3.read(result.text)
        @test haskey(data, "count")
        @test haskey(data, "papers")
        if data["count"] > 0
            p = data["papers"][1]
            @test haskey(p, "arxiv_id")
            @test haskey(p, "title")
            @test haskey(p, "abstract")
            @test p["announce_type"] == "new"
        end
    end

    @testset "fetch_all_daily_updates handler (live)" begin
        t = only(filter(t -> t.name == "fetch_all_daily_updates", FytcMCP_arXiv.server.tools))
        result = t.handler(Dict{String, Any}("category" => "hep-ph"))
        data = JSON3.read(result.text)
        @test data["count"] > 0
    end

    @testset "abstract truncation in handler" begin
        t = only(filter(t -> t.name == "fetch_daily_new_submissions", FytcMCP_arXiv.server.tools))
        result = t.handler(Dict{String, Any}("category" => "hep-ph", "max_abstract_length" => "50"))
        data = JSON3.read(result.text)
        if data["count"] > 0
            p = data["papers"][1]
            @test length(p["abstract"]) <= 53  # 50 + "..."
        end
    end
end
