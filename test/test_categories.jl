@testset "ARXIV_CATEGORIES" begin
    cats = FytcMCP_arXiv.arxiv_categories()

    @testset "is non-empty" begin
        @test !isempty(cats)
    end

    @testset "is a Dict{String,Vector{String}}" begin
        @test isa(cats, Dict{String, Vector{String}})
    end

    @testset "contains essential physics archives" begin
        for essential in ["hep-ph", "hep-th", "hep-ex", "gr-qc", "astro-ph", "cond-mat", "quant-ph"]
            @test haskey(cats, essential)
        end
    end

    @testset "contains essential math archive" begin
        @test haskey(cats, "math")
        @test "math.CO" in cats["math"]
    end

    @testset "contains essential CS archive" begin
        @test haskey(cats, "cs")
        @test "cs.AI" in cats["cs"]
        @test "cs.LG" in cats["cs"]
    end

    @testset "no duplicate sub-categories within any archive" begin
        for (archive, subs) in cats
            @test length(unique(subs)) == length(subs)
        end
    end
end
