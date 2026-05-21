# Copyright (c) 2026 Quan-feng WU <wuquanfeng@ihep.ac.cn>
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

module FytcMCP_arXiv

using ModelContextProtocol
using HTTP
using EzXML
using JSON3

# const ARXIV_RSS_BASE_URL = "http://export.arxiv.org/rss"
const ARXIV_RSS_BASE_URL = "https://rss.arxiv.org/atom/"

## Helper functions
## -----------------------------------------------------------------------------

"""
    fetch_rss_feed(category::String) -> EzXML.Document

Fetch the arXiv RSS feed for a given category.
"""
function fetch_rss_feed(category::String)
    url = ARXIV_RSS_BASE_URL * category
    response = HTTP.get(url; headers=Dict("User-Agent" => "FytcMCP_arXiv/0.1.0"))
    if response.status != 200
        error("Failed to fetch arXiv RSS feed: HTTP $(response.status)")
    end
    return parsexml(String(response.body))
end

"""
    extract_arxiv_id(link::String) -> String

Extract arXiv ID from a URL like `https://arxiv.org/abs/2605.20332`.
"""
function extract_arxiv_id(link::String)
    m = match(r"(\d+\.\d+)", link)
    return m !== nothing ? m.captures[1] : link
end

"""
    parse_description(desc::String) -> Dict

Parse the `<description>` field of an RSS item into structured data.
The description typically looks like:
    `arXiv:2605.20332v1 Announce Type: new \nAbstract: ...`
"""
function parse_description(desc::String)
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
    parse_rss_items(doc::EzXML.Document; announce_type::Union{Nothing, String}=nothing) -> Vector{Dict}

Parse all `<item>` elements from the RSS document.
If `announce_type` is specified (e.g., "new" or "cross"), only items of that type are returned.
"""
function parse_rss_items(doc::EzXML.Document; announce_type::Union{Nothing, String}=nothing)
    items = findall("//channel/item", root(doc))
    results = Dict[]

    for item in items
        title_node = findfirst("title", item)
        link_node = findfirst("link", item)
        desc_node = findfirst("description", item)
        creator_node = findfirst("dc:creator", item)
        announce_node = findfirst("arxiv:announce_type", item)
        category_nodes = findall("category", item)
        pubdate_node = findfirst("pubDate", item)

        item_announce = announce_node !== nothing ? nodecontent(announce_node) : ""

        # Filter by announce type if specified
        if announce_type !== nothing && item_announce != announce_type
            continue
        end

        link = link_node !== nothing ? nodecontent(link_node) : ""
        arxiv_id = extract_arxiv_id(link)
        title = title_node !== nothing ? nodecontent(title_node) : ""
        authors = creator_node !== nothing ? nodecontent(creator_node) : ""
        categories = [nodecontent(c) for c in category_nodes]

        abstract = ""
        if desc_node !== nothing
            desc_text = nodecontent(desc_node)
            parsed_desc = parse_description(desc_text)
            abstract = get(parsed_desc, "abstract", "")
        end

        pub_date = pubdate_node !== nothing ? nodecontent(pubdate_node) : ""

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
    truncate_abstract(paper::Dict, max_length::Int) -> Dict

Return a copy of `paper` with the abstract truncated if needed.
"""
function truncate_abstract(paper::Dict, max_length::Int)
    if max_length > 0 && length(paper["abstract"]) > max_length
        p = copy(paper)
        p["abstract"] = "$(paper["abstract"][1:max_length])..."
        return p
    end
    return paper
end

"""
    papers_to_json(papers::Vector{Dict}; max_abstract_length::Int=0) -> String

Serialize a list of paper Dicts to a JSON string.
"""
function papers_to_json(papers::AbstractVector; max_abstract_length::Int=0)
    result = Dict{String, Any}(
        "count" => length(papers),
        "papers" => [truncate_abstract(p, max_abstract_length) for p in papers],
    )
    return JSON3.write(result)
end

## List of supported arXiv categories
## -----------------------------------------------------------------------------

const ARXIV_CATEGORIES = [
    # Physics
    "astro-ph", "astro-ph.CO", "astro-ph.EP", "astro-ph.GA", "astro-ph.HE", "astro-ph.IM", "astro-ph.SR",
    "cond-mat", "cond-mat.dis-nn", "cond-mat.mes-hall", "cond-mat.mtrl-sci", "cond-mat.other", "cond-mat.quant-gas", "cond-mat.soft", "cond-mat.stat-mech", "cond-mat.str-el", "cond-mat.supr-con",
    "gr-qc",
    "hep-ex", "hep-lat", "hep-ph", "hep-th",
    "math-ph",
    "nlin", "nlin.AO", "nlin.CD", "nlin.CG", "nlin.PS", "nlin.SI",
    "nucl-ex", "nucl-th",
    "physics", "physics.acc-ph", "physics.ao-ph", "physics.app-ph", "physics.atm-clus", "physics.atom-ph", "physics.bio-ph", "physics.chem-ph", "physics.class-ph", "physics.comp-ph", "physics.data-an", "physics.ed-ph", "physics.flu-dyn", "physics.gen-ph", "physics.geo-ph", "physics.hist-ph", "physics.ins-det", "physics.med-ph", "physics.optics", "physics.plasm-ph", "physics.pop-ph", "physics.soc-ph", "physics.space-ph",
    "quant-ph",
    # Mathematics
    "math", "math.AG", "math.AT", "math.AP", "math.CT", "math.CA", "math.CO", "math.AC", "math.CV", "math.DG", "math.DS", "math.FA", "math.GM", "math.GN", "math.GT", "math.GR", "math.HO", "math.IT", "math.KT", "math.LO", "math.MP", "math.MG", "math.NT", "math.NA", "math.OA", "math.OC", "math.PR", "math.QA", "math.RT", "math.RA", "math.SP", "math.ST",
    # Computer Science
    "cs", "cs.AI", "cs.AR", "cs.CC", "cs.CE", "cs.CG", "cs.CL", "cs.CR", "cs.CV", "cs.CY", "cs.DB", "cs.DL", "cs.DM", "cs.DS", "cs.ET", "cs.FL", "cs.GL", "cs.GR", "cs.GT", "cs.HC", "cs.IR", "cs.IT", "cs.LG", "cs.LO", "cs.MA", "cs.MM", "cs.MS", "cs.NA", "cs.NE", "cs.NI", "cs.OH", "cs.OS", "cs.PF", "cs.PL", "cs.RO", "cs.SC", "cs.SD", "cs.SE", "cs.SI", "cs.SY",
    # Quantitative Biology
    "q-bio", "q-bio.BM", "q-bio.CB", "q-bio.GN", "q-bio.MN", "q-bio.NC", "q-bio.OT", "q-bio.PE", "q-bio.QM", "q-bio.SC", "q-bio.TO",
    # Quantitative Finance
    "q-fin", "q-fin.CP", "q-fin.EC", "q-fin.GN", "q-fin.MF", "q-fin.PM", "q-fin.PR", "q-fin.RM", "q-fin.ST", "q-fin.TR",
    # Statistics
    "stat", "stat.AP", "stat.CO", "stat.ML", "stat.ME", "stat.OT", "stat.TH",
    # EESS
    "eess", "eess.AS", "eess.IV", "eess.SP", "eess.SY",
    # Economics
    "econ", "econ.EM", "econ.GN", "econ.TH",
]

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
        filtered = if filter_str != ""
            filter(c -> occursin(lowercase(filter_str), lowercase(c)), ARXIV_CATEGORIES)
        else
            ARXIV_CATEGORIES
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
