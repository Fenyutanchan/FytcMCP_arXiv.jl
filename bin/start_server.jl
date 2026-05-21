#!/usr/bin/env julia
#
# Start the FytcMCP_arXiv MCP server using stdio transport.
# This script is intended to be used as an MCP server entry point.
#
# Usage:
#   julia --project bin/start_server.jl

using FytcMCP_arXiv
using ModelContextProtocol

FytcMCP_arXiv.server |> start!
