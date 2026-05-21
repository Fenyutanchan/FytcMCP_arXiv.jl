# Copyright (c) 2026 Quan-feng WU <wuquanfeng@ihep.ac.cn>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

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
            doc = fetch_atom_feed(category)
            papers = parse_atom_items(doc; announce_type="new")
            return TextContent(text = papers_to_json(papers; max_abstract_length=max_len))
        catch e
            return TextContent(text = JSON3.write(Dict("error" => true, "message" => "Error fetching arXiv Atom feed for category '$category': $e")))
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
            doc = fetch_atom_feed(category)
            papers = parse_atom_items(doc; announce_type="cross")
            return TextContent(text = papers_to_json(papers; max_abstract_length=max_len))
        catch e
            return TextContent(text = JSON3.write(Dict("error" => true, "message" => "Error fetching arXiv Atom feed for category '$category': $e")))
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
            doc = fetch_atom_feed(category)
            papers = parse_atom_items(doc)
            return TextContent(text = papers_to_json(papers; max_abstract_length=max_len))
        catch e
            return TextContent(text = JSON3.write(Dict("error" => true, "message" => "Error fetching arXiv Atom feed for category '$category': $e")))
        end
    end
)

## Constants
## -----------------------------------------------------------------------------

const ARXIV_ATOM_BASE_URL = "https://rss.arxiv.org/atom/"

## Helper functions
## -----------------------------------------------------------------------------

"""
    fetch_atom_feed(category::String)::EzXML.Document

Fetch the arXiv Atom feed for a given category.
"""
function fetch_atom_feed(category::String)::EzXML.Document
    url = ARXIV_ATOM_BASE_URL * category
    response = HTTP.get(url; headers=Dict("User-Agent" => "FytcMCP_arXiv/0.1.0"))
    if response.status != 200
        error("Failed to fetch arXiv Atom feed: HTTP $(response.status)")
    end
    return parsexml(String(response.body))
end

"""
    extract_arXiv_id(link::String)::String

Extract arXiv ID from a URL like `https://arxiv.org/abs/2605.20332`.
"""
function extract_arXiv_id(link::String)::String
    m = match(r"(\d+\.\d+)", link)
    return m !== nothing ? m.captures[1] : link
end

"""
    parse_description(desc::String)::Dict{String, String}

Parse the `<description>` field of an Atom entry into structured data.
The description typically looks like:
    `arXiv:2605.20332v1 Announce Type: new \\nAbstract: ...`
"""
function parse_description(desc::String)::Dict{String, String}
    result = Dict{String, String}()

    # Extract announce type
    type_match = match(r"Announce Type:\s*(\w+)", desc)
    if type_match !== nothing
        result["announce_type"] = type_match.captures[1]
    end

    # Extract abstract
    abstract_match = match(r"Abstract:\s*(.+)"s, desc)
    if abstract_match !== nothing
        result["abstract"] = strip(abstract_match.captures[1])
    end

    return result
end

"""
    _find_child(parent::EzXML.Node, name::String)::Union{EzXML.Node, Nothing}

Find the first child element whose local name matches `name`, regardless of namespace.
"""
function _find_child(parent::EzXML.Node, name::String)::Union{EzXML.Node, Nothing}
    for child in eachelement(parent)
        nodename(child) == name && return child
    end
    return nothing
end

"""
    _find_children(parent::EzXML.Node, name::String)::Vector{EzXML.Node}

Find all child elements whose local name matches `name`, regardless of namespace.
"""
function _find_children(parent::EzXML.Node, name::String)::Vector{EzXML.Node}
    result = EzXML.Node[]
    for child in eachelement(parent)
        nodename(child) == name && push!(result, child)
    end
    return result
end

"""
    parse_atom_entries(feed::EzXML.Node; announce_type::Union{Nothing, String}=nothing)::Vector{Dict}

Parse `<entry>` elements from an Atom `<feed>`.
If `announce_type` is specified (e.g., "new" or "cross"), only entries of that type are returned.
"""
function parse_atom_entries(feed::EzXML.Node; announce_type::Union{Nothing, String}=nothing)::Vector{Dict}
    results = Dict[]

    for entry in _find_children(feed, "entry")
        announce_node = _find_child(entry, "announce_type")
        item_announce = announce_node !== nothing ? nodecontent(announce_node) : ""

        announce_type !== nothing && item_announce != announce_type && continue

        title_node = _find_child(entry, "title")
        title = title_node !== nothing ? nodecontent(title_node) : ""
        link_node = _find_child(entry, "link")
        link = link_node !== nothing ? link_node["href"] : ""
        arXiv_id = extract_arXiv_id(link)

        creator_node = _find_child(entry, "creator")
        authors = creator_node !== nothing ? nodecontent(creator_node) : ""

        categories = String[]
        for cat_node in _find_children(entry, "category")
            try push!(categories, cat_node["term"]) catch; end
        end

        abstract = ""
        summary_node = _find_child(entry, "summary")
        if summary_node !== nothing
            parsed = parse_description(nodecontent(summary_node))
            abstract = get(parsed, "abstract", "")
        end

        pub_date_node = _find_child(entry, "published")
        pub_date = pub_date_node !== nothing ? nodecontent(pub_date_node) : ""

        push!(results, Dict(
            "arXiv_id" => arXiv_id,
            "title" => title,
            "authors" => authors,
            "abstract" => abstract,
            "link" => link,
            "categories" => categories,
            "announce_type" => item_announce,
            "pub_date" => pub_date,
        ))
    end

    return results
end

"""
    parse_atom_items(doc::EzXML.Document; announce_type::Union{Nothing, String}=nothing)::Vector{Dict}

Parse `<entry>` elements from an arXiv Atom feed document.
If `announce_type` is specified (e.g., "new" or "cross"), only entries of that type are returned.
"""
function parse_atom_items(doc::EzXML.Document; announce_type::Union{Nothing, String}=nothing)::Vector{Dict}
    return parse_atom_entries(root(doc); announce_type)
end

"""
    truncate_abstract(paper::Dict, max_length::Int)::Dict

Return a copy of `paper` with the abstract truncated if needed.
"""
function truncate_abstract(paper::Dict, max_length::Int)::Dict
    max_length > 0 && length(paper["abstract"]) > max_length || return paper
    Dict(paper..., "abstract" => paper["abstract"][1:max_length] * "...")
end

"""
    papers_to_json(papers::Vector{<:Dict}; max_abstract_length::Int=0)::String

Serialize a list of paper Dicts to a JSON string.
"""
function papers_to_json(papers::Vector{<:Dict}; max_abstract_length::Int=0)::String
    result = Dict{String, Any}(
        "count" => length(papers),
        "papers" => [truncate_abstract(p, max_abstract_length) for p in papers],
    )
    return JSON3.write(result)
end

