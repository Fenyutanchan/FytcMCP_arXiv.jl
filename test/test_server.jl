@testset "Server" begin
    s = FytcMCP_arXiv.server

    @testset "server config" begin
        @test s.config.name == "FytcMCP_arXiv"
        @test s.config.version == "0.1.0"
    end

    @testset "server has 5 tools" begin
        @test length(s.tools) == 5
    end

    @testset "server is exported" begin
        @test isdefined(FytcMCP_arXiv, :server)
    end
end
