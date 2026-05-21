# Copyright (c) 2026 Quan-feng WU <wuquanfeng@ihep.ac.cn>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

## Constants
## -----------------------------------------------------------------------------

const ARXIV_RSS_BASE_URL = "https://rss.arxiv.org/atom/"

const _ARXIV_CATEGORIES_CACHE = Ref{Vector{String}}(String[])

"""
    fetch_arxiv_categories()::Vector{String}

Fetch the list of arXiv category identifiers from `https://arxiv.org/category_taxonomy`.
Extracts category IDs from `<h4>` elements (e.g. `cs.AI`, `hep-ph`) and prepends
top-level archive IDs (e.g. `astro-ph`, `cs`, `math`) derived from the sub-categories.
"""
function fetch_arxiv_categories()::Vector{String}
    url = "https://arxiv.org/category_taxonomy"
    response = HTTP.get(url; headers=Dict("User-Agent" => "FytcMCP_arXiv/0.1.0"))
    if response.status != 200
        error("Failed to fetch arXiv category taxonomy: HTTP $(response.status)")
    end

    doc = parsehtml(String(response.body))

    # Extract category IDs from all <h4> elements
    categories = String[]
    for h4 in findall("//h4", doc)
        text = strip(nodecontent(h4))
        m = match(r"^([a-z][\w-]+(?:\.[A-Z][\w-]+)?)", text)
        if m !== nothing
            push!(categories, m.captures[1])
        end
    end

    # Derive top-level archive IDs (prefixes before the dot) and merge
    archives = Set{String}()
    for cat in categories
        occursin('.', cat) && push!(archives, cat[1:findfirst('.', cat)-1])
    end

    return sort(unique(vcat(collect(archives), categories)))
end

"""
    arxiv_categories()::Vector{String}

Return the cached list of arXiv categories, fetching on first call.
"""
function arxiv_categories()::Vector{String}
    if isempty(_ARXIV_CATEGORIES_CACHE[])
        _ARXIV_CATEGORIES_CACHE[] = fetch_arxiv_categories()
    end
    return _ARXIV_CATEGORIES_CACHE[]
end

## Helper functions
## -----------------------------------------------------------------------------

"""
    fetch_rss_feed(category::String)::EzXML.Document

Fetch the arXiv Atom feed for a given category.
"""
function fetch_rss_feed(category::String)::EzXML.Document
    url = ARXIV_RSS_BASE_URL * category
    response = HTTP.get(url; headers=Dict("User-Agent" => "FytcMCP_arXiv/0.1.0"))
    if response.status != 200
        error("Failed to fetch arXiv Atom feed: HTTP $(response.status)")
    end
    return parsexml(String(response.body))
end

"""
    extract_arxiv_id(link::String)::String

Extract arXiv ID from a URL like `https://arxiv.org/abs/2605.20332`.
"""
function extract_arxiv_id(link::String)::String
    m = match(r"(\d+\.\d+)", link)
    return m !== nothing ? m.captures[1] : link
end

"""
    parse_description(desc::String)::Dict{String, String}

Parse the `<description>` field of an RSS item into structured data.
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
        arxiv_id = extract_arxiv_id(link)

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
            "arxiv_id" => arxiv_id,
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
    parse_rss_items(doc::EzXML.Document; announce_type::Union{Nothing, String}=nothing)::Vector{Dict}

Parse `<entry>` elements from an arXiv Atom feed document.
If `announce_type` is specified (e.g., "new" or "cross"), only entries of that type are returned.
"""
function parse_rss_items(doc::EzXML.Document; announce_type::Union{Nothing, String}=nothing)::Vector{Dict}
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

