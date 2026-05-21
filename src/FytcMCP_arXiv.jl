# Copyright (c) 2026 Quan-feng WU <wuquanfeng@ihep.ac.cn>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module FytcMCP_arXiv

using ModelContextProtocol
using HTTP
using EzXML
using JSON3

include("categories.jl")
include("daily.jl")

## MCP Tools
## -----------------------------------------------------------------------------

"""
Tool: get_arXiv_paper
Fetch the details of a specific arXiv paper by its ID from the Atom feed.
"""
get_arXiv_paper_tool = MCPTool(
    name = "get_arXiv_paper",
    description = "Get the full details (title, authors, abstract, categories) of a specific arXiv paper by its ID (e.g., \"2605.20332\"). This fetches from the daily Atom feed.",
    parameters = [
        ToolParameter(
            name = "arXiv_id",
            type = "string",
            description = "arXiv paper ID (e.g., \"2605.20332\").",
            required = true
        ),
        ToolParameter(
            name = "category",
            type = "string",
            description = "arXiv category to search in (e.g., \"hep-ph\"). If not specified, tries common categories.",
            required = false
        )
    ],
    handler = function(params)
        arXiv_id = params["arXiv_id"]
        specified_category = get(params, "category", nothing)

        # Categories to search
        categories_to_search = if specified_category !== nothing
            [specified_category]
        else
            # Try to infer from the paper ID or search common physics categories
            ["hep-ph", "hep-th", "hep-ex", "gr-qc", "astro-ph.HE", "cond-mat", "quant-ph", "cs.AI", "math-ph"]
        end

        for cat in categories_to_search
            try
                doc = fetch_atom_feed(cat)
                papers = parse_atom_items(doc)
                for paper in papers
                    if paper["arXiv_id"] == arXiv_id
                        return TextContent(text = JSON3.write(paper))
                    end
                end
            catch
                continue
            end
        end

        return TextContent(text = JSON3.write(Dict("error" => true, "message" => "Paper with arXiv ID '$arXiv_id' not found in recent Atom feeds. Try specifying the category parameter.")))
    end
)

## Server
## -----------------------------------------------------------------------------

server = mcp_server(
    name = "FytcMCP_arXiv",
    version = "0.1.0",
    description = "Fytc's MCP server for accessing arXiv (https://arxiv.org).",
    tools = [
        fetch_daily_new_submissions_tool,
        fetch_daily_cross_listed_tool,
        fetch_all_daily_updates_tool,
        get_arXiv_paper_tool,
        list_arXiv_categories_tool,
    ]
)

end # module FytcMCP_arXiv
