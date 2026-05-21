# Copyright (c) 2026 Quan-feng WU <wuquanfeng@ihep.ac.cn>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module FytcMCP_arXiv

using ModelContextProtocol
using HTTP
using EzXML
using JSON3

include("everyday.jl")

## MCP Tools
## -----------------------------------------------------------------------------

"""
Tool: fetch_daily_new_submissions
Fetch today's new arXiv submissions for a given category.
"""
fetch_daily_new_submissions_tool = MCPTool(
    name = "fetch_daily_new_submissions",
    description = "Fetch today's new arXiv submissions for a given category. Returns a list of newly submitted papers with titles, authors, abstracts, and links.",
    parameters = [
        ToolParameter(
            name = "category",
            type = "string",
            description = "arXiv category (e.g., \"hep-ph\", \"cs.AI\", \"math.CO\", \"cond-mat.mes-hall\"). Use the top-level category (e.g., \"hep-ph\") for all subcategories.",
            required = true
        ),
        ToolParameter(
            name = "max_abstract_length",
            type = "integer",
            description = "Maximum length of each abstract to display. 0 means no truncation. Default: 500.",
            required = false,
            default = 500
        )
    ],
    handler = function(params)
        category = params["category"]
        max_len = get(params, "max_abstract_length", 500)
        if isa(max_len, String)
            max_len = parse(Int, max_len)
        end

        try
            doc = fetch_rss_feed(category)
            papers = parse_rss_items(doc; announce_type="new")
            return TextContent(text = papers_to_json(papers; max_abstract_length=max_len))
        catch e
            return TextContent(text = JSON3.write(Dict("error" => true, "message" => "Error fetching arXiv RSS feed for category '$category': $e")))
        end
    end
)

"""
Tool: fetch_daily_cross_listed
Fetch today's cross-listed arXiv papers for a given category.
Cross-listed papers are primarily submitted to other categories but are relevant to this one.
"""
fetch_daily_cross_listed_tool = MCPTool(
    name = "fetch_daily_cross_listed",
    description = "Fetch today's cross-listed arXiv papers for a given category. These are papers primarily submitted to other categories but cross-listed as relevant to the specified category.",
    parameters = [
        ToolParameter(
            name = "category",
            type = "string",
            description = "arXiv category (e.g., \"hep-ph\", \"cs.AI\", \"math.CO\").",
            required = true
        ),
        ToolParameter(
            name = "max_abstract_length",
            type = "integer",
            description = "Maximum length of each abstract to display. 0 means no truncation. Default: 500.",
            required = false,
            default = 500
        )
    ],
    handler = function(params)
        category = params["category"]
        max_len = get(params, "max_abstract_length", 500)
        if isa(max_len, String)
            max_len = parse(Int, max_len)
        end

        try
            doc = fetch_rss_feed(category)
            papers = parse_rss_items(doc; announce_type="cross")
            return TextContent(text = papers_to_json(papers; max_abstract_length=max_len))
        catch e
            return TextContent(text = JSON3.write(Dict("error" => true, "message" => "Error fetching arXiv RSS feed for category '$category': $e")))
        end
    end
)

"""
Tool: fetch_all_daily_updates
Fetch all today's arXiv updates (new + cross-listed) for a given category.
"""
fetch_all_daily_updates_tool = MCPTool(
    name = "fetch_all_daily_updates",
    description = "Fetch all today's arXiv updates (both new submissions and cross-listed papers) for a given category.",
    parameters = [
        ToolParameter(
            name = "category",
            type = "string",
            description = "arXiv category (e.g., \"hep-ph\", \"cs.AI\", \"math.CO\").",
            required = true
        ),
        ToolParameter(
            name = "max_abstract_length",
            type = "integer",
            description = "Maximum length of each abstract to display. 0 means no truncation. Default: 500.",
            required = false,
            default = 500
        )
    ],
    handler = function(params)
        category = params["category"]
        max_len = get(params, "max_abstract_length", 500)
        if isa(max_len, String)
            max_len = parse(Int, max_len)
        end

        try
            doc = fetch_rss_feed(category)
            papers = parse_rss_items(doc)
            return TextContent(text = papers_to_json(papers; max_abstract_length=max_len))
        catch e
            return TextContent(text = JSON3.write(Dict("error" => true, "message" => "Error fetching arXiv RSS feed for category '$category': $e")))
        end
    end
)

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

"""
Tool: list_arxiv_categories
List the supported arXiv categories.
"""
list_arxiv_categories_tool = MCPTool(
    name = "list_arxiv_categories",
    description = "List all supported arXiv category identifiers that can be used with the fetch tools.",
    parameters = [
        ToolParameter(
            name = "filter",
            type = "string",
            description = "Optional filter string to search for specific categories (e.g., \"hep\", \"cs\", \"math\").",
            required = false
        )
    ],
    handler = function(params)
        filter_str = get(params, "filter", "")
        cats = arxiv_categories()
        filtered = if filter_str != ""
            filter(c -> occursin(lowercase(filter_str), lowercase(c)), cats)
        else
            cats
        end

        # Group by top-level category
        groups = Dict{String, Vector{String}}()
        for cat in filtered
            top = split(cat, ".")[1]
            if !haskey(groups, top)
                groups[top] = String[]
            end
            push!(groups[top], cat)
        end

        result = Dict{String, Any}(
            "count" => length(filtered),
            "filter" => filter_str != "" ? filter_str : nothing,
            "categories" => groups,
        )
        return TextContent(text = JSON3.write(result))
    end
)

## Server setup
## -----------------------------------------------------------------------------

server = mcp_server(
    name = "FytcMCP_arXiv",
    version = "0.1.0",
    description = "MCP server for fetching daily arXiv updates via RSS/Atom feeds.",
    tools = [
        fetch_daily_new_submissions_tool,
        fetch_daily_cross_listed_tool,
        fetch_all_daily_updates_tool,
        get_arxiv_paper_tool,
        list_arxiv_categories_tool,
    ]
)

export server

end # module FytcMCP_arXiv
