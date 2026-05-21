# Copyright (c) 2026 Quan-feng WU <wuquanfeng@ihep.ac.cn>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## MCP Tools
## -----------------------------------------------------------------------------

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
        ),
        ToolParameter(
            name = "refresh",
            type = "boolean",
            description = "Force re-fetch the category list from arXiv taxonomy page. Default: false.",
            required = false
        )
    ],
    handler = function(params)
        filter_str = get(params, "filter", "")
        do_refresh = get(params, "refresh", false)
        if isa(do_refresh, String)
            do_refresh = parse(Bool, do_refresh)
        end
        cats = arxiv_categories(; refresh=do_refresh)
        filtered = if filter_str != ""
            result = Dict{String, Vector{String}}()
            for (top, subs) in cats
                if occursin(lowercase(filter_str), lowercase(top))
                    result[top] = subs
                else
                    matched = filter(c -> occursin(lowercase(filter_str), lowercase(c)), subs)
                    if !isempty(matched)
                        result[top] = matched
                    end
                end
            end
            result
        else
            cats
        end

        count = isempty(filtered) ? 0 : sum(length(v) for v in values(filtered))
        result = Dict{String, Any}(
            "count" => count,
            "filter" => filter_str != "" ? filter_str : nothing,
            "categories" => filtered,
        )
        return TextContent(text = JSON3.write(result))
    end
)

## Constants
## -----------------------------------------------------------------------------

const _ARXIV_CATEGORIES_CACHE = Dict{String, Vector{String}}()

## Helper functions
## -----------------------------------------------------------------------------

"""
    fetch_arxiv_categories()::Dict{String, Vector{String}}

Fetch the list of arXiv category identifiers from `https://arxiv.org/category_taxonomy`.
Extracts category IDs from `<h4>` elements and organizes them into a hierarchy:
top-level archives (e.g. `cs`, `astro-ph`) map to their sub-categories (e.g. `cs.AI`, `astro-ph.CO`).
Archives without sub-categories map to an empty vector.
"""
function fetch_arxiv_categories()::Dict{String, Vector{String}}
    url = "https://arxiv.org/category_taxonomy"
    response = HTTP.get(url; headers=Dict("User-Agent" => "FytcMCP_arXiv/0.1.0"))
    if response.status != 200
        error("Failed to fetch arXiv category taxonomy: HTTP $(response.status)")
    end

    doc = parsehtml(String(response.body))

    # Extract category IDs from all <h4> elements
    raw_categories = String[]
    for h4 in findall("//h4", doc)
        text = strip(nodecontent(h4))
        m = match(r"^([a-z][\w-]+(?:\.[A-Z][\w-]+)?)", text)
        if m !== nothing
            push!(raw_categories, m.captures[1])
        end
    end

    # Build hierarchy: top-level archive → sub-categories
    result = Dict{String, Vector{String}}()
    for cat in raw_categories
        top = occursin('.', cat) ? cat[1:findfirst('.', cat)-1] : cat
        if !haskey(result, top)
            result[top] = String[]
        end
        occursin('.', cat) && push!(result[top], cat)
    end
    for k in keys(result)
        sort!(result[k])
    end

    return result
end

"""
    arxiv_categories(; refresh::Bool=false)::Dict{String, Vector{String}}

Return the cached hierarchy of arXiv categories, fetching on first call.
Set `refresh=true` to force re-fetch from the taxonomy page.
"""
function arxiv_categories(; refresh::Bool=false)::Dict{String, Vector{String}}
    if isempty(_ARXIV_CATEGORIES_CACHE) || refresh
        empty!(_ARXIV_CATEGORIES_CACHE)
        merge!(_ARXIV_CATEGORIES_CACHE, fetch_arxiv_categories())
    end
    return _ARXIV_CATEGORIES_CACHE
end
