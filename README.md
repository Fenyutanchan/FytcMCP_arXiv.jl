# Model Context Protocol for arXiv

An MCP (Model Context Protocol) server for arXiv (https://arxiv.org) manipulations.

## Features

Provides 5 MCP tools for interacting with arXiv:

| Tool | Description |
|------|-------------|
| `fetch_daily_new_submissions` | Fetch today's new arXiv submissions for a given category |
| `fetch_daily_cross_listed` | Fetch today's cross-listed papers for a given category |
| `fetch_all_daily_updates` | Fetch all today's updates (new + cross-listed) for a given category |
| `get_arxiv_paper` | Get details of a specific arXiv paper by its ID |
| `list_arxiv_categories` | List all supported arXiv category identifiers |

## Usage

### Start the MCP server (stdio transport)

```bash
/path/to/FytcMCP_arXiv/bin/start_server.jl
```

### Configure in MCP client (e.g., Claude Desktop, VS Code Copilot)

Add to your MCP settings:

```json
{
  "mcpServers": {
    "FytcMCP_arXiv": {
      "command": "/path/to/FytcMCP_arXiv/bin/start_server.jl"
    }
  }
}
```

## Supported Categories

Supports all arXiv categories including:
- **Physics:** `hep-ph`, `hep-th`, `astro-ph`, `cond-mat`, `quant-ph`, etc.
- **Mathematics:** `math.CO`, `math.DG`, `math.NT`, etc.
- **Computer Science:** `cs.AI`, `cs.CL`, `cs.LG`, etc.
- **Statistics:** `stat.ML`, `stat.TH`, etc.
- And many more. Use the `list_arxiv_categories` tool to see all options.
