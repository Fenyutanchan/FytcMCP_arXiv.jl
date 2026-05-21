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
Tool: get_arxiv_paper
Fetch the details of a specific arXiv paper by its ID from the RSS feed.
"""
get_arxiv_paper_tool = MCPTool(
    name = "get_arxiv_paper",
    description = "Get the full details (title, authors, abstract, categories) of a specific arXiv paper by its ID (e.g., \"2605.20332\"). This fetches from the daily RSS feed.",
    parameters = [
        ToolParameter(
            name = "arxiv_id",
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
        arxiv_id = params["arxiv_id"]
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
                doc = fetch_rss_feed(cat)
                papers = parse_rss_items(doc)
                for paper in papers
                    if paper["arxiv_id"] == arxiv_id
                        return TextContent(text = JSON3.write(paper))
                    end
                end
            catch
                continue
            end
        end

        return TextContent(text = JSON3.write(Dict("error" => true, "message" => "Paper with arXiv ID '$arxiv_id' not found in recent RSS feeds. Try specifying the category parameter.")))
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
        get_arxiv_paper_tool,
        list_arxiv_categories_tool,
    ]
)

end # module FytcMCP_arXiv
