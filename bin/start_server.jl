#!/usr/bin/env julia
#
# Start the FytcMCP_arXiv MCP server using stdio transport.
# This script is intended to be used as an MCP server entry point.
#
# Usage:
#   /path/to/FytcMCP_arXiv/bin/start_server.jl

import Pkg

joinpath(dirname(@__DIR__), "Project.toml") |> Pkg.activate
Pkg.instantiate()

using FytcMCP_arXiv
using ModelContextProtocol

FytcMCP_arXiv.server |> start!
