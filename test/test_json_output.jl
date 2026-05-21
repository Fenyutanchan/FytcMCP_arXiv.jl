@testset "truncate_abstract" begin
    paper = Dict{String, Any}(
        "arxiv_id" => "2605.10003",
        "title" => "Test",
        "abstract" => "A" ^ 200,
    )

    @testset "no truncation when max_length is 0" begin
        result = FytcMCP_arXiv.truncate_abstract(paper, 0)
        @test length(result["abstract"]) == 200
    end

    @testset "no truncation when abstract is shorter than max_length" begin
        result = FytcMCP_arXiv.truncate_abstract(paper, 300)
        @test length(result["abstract"]) == 200
    end

    @testset "truncation applied when abstract exceeds max_length" begin
        result = FytcMCP_arXiv.truncate_abstract(paper, 50)
        @test length(result["abstract"]) == 53  # 50 chars + "..."
        @test endswith(result["abstract"], "...")
        @test startswith(result["abstract"], "A" ^ 50)
    end

    @testset "original paper is not mutated" begin
        original_len = length(paper["abstract"])
        FytcMCP_arXiv.truncate_abstract(paper, 10)
        @test length(paper["abstract"]) == original_len
    end
end

@testset "papers_to_json" begin
    papers = [
        Dict{String, Any}(
            "arxiv_id" => "2605.10001",
            "title" => "Paper One",
            "authors" => "Author A",
            "abstract" => "Short abstract.",
            "link" => "https://arxiv.org/abs/2605.10001",
            "categories" => ["hep-ph"],
            "announce_type" => "new",
            "pub_date" => "Wed, 21 May 2026 00:00:00 -0400",
        ),
        Dict{String, Any}(
            "arxiv_id" => "2605.10002",
            "title" => "Paper Two",
            "authors" => "Author B",
            "abstract" => "Another abstract.",
            "link" => "https://arxiv.org/abs/2605.10002",
            "categories" => ["hep-ph", "astro-ph.HE"],
            "announce_type" => "cross",
            "pub_date" => "Wed, 21 May 2026 00:00:00 -0400",
        ),
    ]

    @testset "basic JSON serialization" begin
        json_str = FytcMCP_arXiv.papers_to_json(papers)
        result = JSON3.read(json_str)
        @test result["count"] == 2
        @test length(result["papers"]) == 2
        @test result["papers"][1]["arxiv_id"] == "2605.10001"
        @test result["papers"][2]["title"] == "Paper Two"
    end

    @testset "empty papers list" begin
        json_str = FytcMCP_arXiv.papers_to_json(Dict[])
        result = JSON3.read(json_str)
        @test result["count"] == 0
        @test isempty(result["papers"])
    end

    @testset "truncation via max_abstract_length" begin
        long_papers = [Dict{String, Any}(
            "arxiv_id" => "2605.10001",
            "title" => "Paper",
            "authors" => "Author",
            "abstract" => "X" ^ 200,
            "link" => "https://arxiv.org/abs/2605.10001",
            "categories" => String[],
            "announce_type" => "new",
            "pub_date" => "date",
        )]
        json_str = FytcMCP_arXiv.papers_to_json(long_papers; max_abstract_length=50)
        result = JSON3.read(json_str)
        @test length(result["papers"][1]["abstract"]) == 53  # 50 + "..."
    end

    @testset "output is valid JSON" begin
        json_str = FytcMCP_arXiv.papers_to_json(papers)
        @test JSON3.read(json_str) !== nothing  # does not throw
    end
end
