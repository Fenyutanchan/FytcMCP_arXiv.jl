@testset "extract_arXiv_id" begin
    @test FytcMCP_arXiv.extract_arXiv_id("https://arxiv.org/abs/2605.20332") == "2605.20332"
    @test FytcMCP_arXiv.extract_arXiv_id("https://arxiv.org/abs/2605.10003") == "2605.10003"
    @test FytcMCP_arXiv.extract_arXiv_id("some text without id") == "some text without id"
    @test FytcMCP_arXiv.extract_arXiv_id("https://arxiv.org/abs/1234.56789") == "1234.56789"
    @test FytcMCP_arXiv.extract_arXiv_id("") == ""
end
