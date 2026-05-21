@testset "ARXIV_CATEGORIES" begin
    cats = FytcMCP_arXiv.ARXIV_CATEGORIES

    @testset "is non-empty" begin
        @test !isempty(cats)
    end

    @testset "contains essential physics categories" begin
        for essential in ["hep-ph", "hep-th", "hep-ex", "gr-qc", "astro-ph", "cond-mat", "quant-ph"]
            @test essential in cats
        end
    end

    @testset "contains essential math categories" begin
        @test "math" in cats
        @test "math.CO" in cats
    end

    @testset "contains essential CS categories" begin
        @test "cs" in cats
        @test "cs.AI" in cats
        @test "cs.LG" in cats
    end

    @testset "all entries are strings" begin
        @test all(c -> isa(c, String), cats)
    end

    @testset "no duplicates" begin
        @test length(unique(cats)) == length(cats)
    end
end
