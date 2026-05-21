@testset "parse_rss_items" begin
    @testset "parse all items from sample RSS" begin
        doc = parsexml(SAMPLE_RSS)
        papers = FytcMCP_arXiv.parse_rss_items(doc)
        @test length(papers) == 4

        # Check first paper (new)
        p1 = papers[1]
        @test p1["arxiv_id"] == "2605.10001"
        @test p1["title"] == "Test Paper One: A Study of Something"
        @test p1["authors"] == "Alice Smith, Bob Jones"
        @test p1["link"] == "https://arxiv.org/abs/2605.10001"
        @test "hep-ph" in p1["categories"]
        @test "hep-th" in p1["categories"]
        @test p1["announce_type"] == "new"
        @test occursin("first test paper", p1["abstract"])
    end

    @testset "parse cross-listed items only" begin
        doc = parsexml(SAMPLE_RSS)
        papers = FytcMCP_arXiv.parse_rss_items(doc; announce_type="cross")
        @test length(papers) == 1
        @test papers[1]["arxiv_id"] == "2605.10002"
        @test papers[1]["announce_type"] == "cross"
        @test papers[1]["authors"] == "Carol Lee"
    end

    @testset "parse new submissions only" begin
        doc = parsexml(SAMPLE_RSS)
        papers = FytcMCP_arXiv.parse_rss_items(doc; announce_type="new")
        @test length(papers) == 2
        ids = [p["arxiv_id"] for p in papers]
        @test "2605.10001" in ids
        @test "2605.10003" in ids
    end

    @testset "parse replaced papers only" begin
        doc = parsexml(SAMPLE_RSS)
        papers = FytcMCP_arXiv.parse_rss_items(doc; announce_type="rep")
        @test length(papers) == 1
        @test papers[1]["arxiv_id"] == "2605.10004"
    end

    @testset "empty RSS returns no items" begin
        doc = parsexml(EMPTY_RSS)
        papers = FytcMCP_arXiv.parse_rss_items(doc)
        @test isempty(papers)
    end

    @testset "filter returns empty for non-existent type" begin
        doc = parsexml(SAMPLE_RSS)
        papers = FytcMCP_arXiv.parse_rss_items(doc; announce_type="nonexistent")
        @test isempty(papers)
    end

    @testset "item with missing optional fields" begin
        doc = parsexml(MINIMAL_ITEM_RSS)
        papers = FytcMCP_arXiv.parse_rss_items(doc)
        @test length(papers) == 1
        p = papers[1]
        @test p["title"] == "Minimal Paper"
        @test p["arxiv_id"] == "2605.99999"
        @test p["authors"] == ""
        @test p["announce_type"] == ""
    end
end
