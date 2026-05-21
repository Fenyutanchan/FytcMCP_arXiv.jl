@testset "parse_rss_items (live Atom feed)" begin
    doc = FytcMCP_arXiv.fetch_rss_feed("hep-ph")
    all_papers = FytcMCP_arXiv.parse_rss_items(doc)

    @testset "returns non-empty results" begin
        @test !isempty(all_papers)
    end

    @testset "each paper has expected fields" begin
        for p in all_papers
            @test haskey(p, "arxiv_id")
            @test haskey(p, "title")
            @test haskey(p, "authors")
            @test haskey(p, "abstract")
            @test haskey(p, "link")
            @test haskey(p, "categories")
            @test haskey(p, "announce_type")
            @test haskey(p, "pub_date")
            @test !isempty(p["arxiv_id"])
            @test !isempty(p["title"])
            @test !isempty(p["link"])
        end
    end

    @testset "arxiv_id is extractable from link" begin
        for p in all_papers
            @test occursin(p["arxiv_id"], p["link"])
        end
    end

    @testset "announce_type filtering works" begin
        types = unique([p["announce_type"] for p in all_papers])
        for t in types
            filtered = FytcMCP_arXiv.parse_rss_items(doc; announce_type=t)
            @test !isempty(filtered)
            @test all(p -> p["announce_type"] == t, filtered)
            # Filtered count matches the count in unfiltered
            @test count(p -> p["announce_type"] == t, all_papers) == length(filtered)
        end
    end

    @testset "non-existent announce_type returns empty" begin
        @test isempty(FytcMCP_arXiv.parse_rss_items(doc; announce_type="nonexistent"))
    end

    @testset "categories contain hep-ph" begin
        @test any(p -> "hep-ph" in p["categories"], all_papers)
    end

    @testset "link is a valid arxiv URL" begin
        for p in all_papers
            @test startswith(p["link"], "https://arxiv.org/abs/")
        end
    end
end
