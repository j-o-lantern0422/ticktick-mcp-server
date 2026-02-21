# ticktick-mcp-server

A Ruby gem that exposes the [TickTick Open API](https://developer.ticktick.com/) as an [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) server. This allows LLMs like Claude to manage your TickTick projects and tasks directly.

## Requirements

- A TickTick account with an Open API access token
- One of the following:
  - Docker (recommended — no Ruby required)
  - Ruby >= 3.1.0

## Installation

### Option 1: Docker (recommended)

No Ruby installation required. Pull the pre-built image from GitHub Container Registry:

```bash
docker pull ghcr.io/j-o-lantern0422/ticktick-mcp-server:latest
```

Or build locally from the repository:

```bash
docker build -t ticktick-mcp-server https://github.com/j-o-lantern0422/ticktick-mcp-server.git#main
```

### Option 2: RubyGems

```bash
gem install ticktick-mcp-server
```

### Option 3: Clone the repository

```bash
git clone https://github.com/j-o-lantern0422/ticktick-mcp-server
cd ticktick-mcp-server
bundle install
bundle exec rake install
```

## Configuration

Set the following environment variable with your TickTick Open API access token:

```
TICKTICK_ACCESS_TOKEN=your_access_token_here
```

### Getting an Access Token

Use the built-in `ticktick-auth` tool to obtain a token via OAuth2.

#### Step 1: Register your application

Go to the [TickTick Developer Center](https://developer.ticktick.com/) and create an OAuth2 application.
Set the redirect URI to:

```
http://localhost:8585/callback
```

#### Step 2: Run the authentication tool

**With Docker:**

```bash
docker run --rm -p 8585:8585 ghcr.io/j-o-lantern0422/ticktick-mcp-server:latest \
  ticktick-auth --client-id=YOUR_CLIENT_ID --client-secret=YOUR_CLIENT_SECRET
```

**With the gem installed locally:**

```bash
ticktick-auth --client-id=YOUR_CLIENT_ID --client-secret=YOUR_CLIENT_SECRET
```

You can also pass credentials via environment variables instead of flags:

```bash
export TICKTICK_CLIENT_ID=YOUR_CLIENT_ID
export TICKTICK_CLIENT_SECRET=YOUR_CLIENT_SECRET
ticktick-auth
```

> **Note:** The default callback port is `8585`. Use `--port PORT` (or `TICKTICK_AUTH_PORT`) to change it.
> If you change the port, update the redirect URI in the developer settings accordingly.

#### Step 3: Authorize in the browser

The tool will print an authorization URL. Open it in your browser and approve the request.

#### Step 4: Copy the token

After authorization, the token is printed to stdout:

```
TICKTICK_ACCESS_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Copy this value and use it as your `TICKTICK_ACCESS_TOKEN`.

## Usage

### Running with Docker

Add the following to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "ticktick": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-e",
        "TICKTICK_ACCESS_TOKEN=your_access_token_here",
        "ghcr.io/j-o-lantern0422/ticktick-mcp-server:latest"
      ]
    }
  }
}
```

> **Note:**
> - `-i` is required for STDIO communication between Claude Desktop and the MCP server.
> - Do **not** use `-t` (pseudo-tty). It causes CR/LF conversion that breaks the JSON-RPC protocol.
> - `--rm` automatically removes the container when the session ends.

### Claude Desktop Integration (gem installed locally)

Add the following to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "ticktick": {
      "command": "ticktick-mcp-server",
      "env": {
        "TICKTICK_ACCESS_TOKEN": "your_access_token_here"
      }
    }
  }
}
```

### Running Locally Without Installing the Gem

If you prefer to run the server directly from the cloned repository:

```json
{
  "mcpServers": {
    "ticktick": {
      "command": "bundle",
      "args": ["exec", "exe/ticktick-mcp-server"],
      "cwd": "/path/to/ticktick-mcp-server",
      "env": {
        "TICKTICK_ACCESS_TOKEN": "your_access_token_here"
      }
    }
  }
}
```

## Available Tools

### Project Management

| Tool | Description | Required Arguments |
|---|---|---|
| `list_projects` | List all projects | — |
| `get_project` | Get a project by ID | `project_id` |
| `get_project_data` | Get project details including tasks and columns | `project_id` |
| `create_project` | Create a new project | `name` |
| `update_project` | Update an existing project | `project_id` |
| `delete_project` | Delete a project | `project_id` |

### Task Management

| Tool | Description | Required Arguments |
|---|---|---|
| `list_all_tasks` | List all tasks across all projects | — |
| `create_task` | Create a new task | `title`, `project_id` |
| `update_task` | Update an existing task | `task_id`, `project_id` |
| `complete_task` | Mark a task as complete | `project_id`, `task_id` |
| `delete_task` | Delete a task | `project_id`, `task_id` |

## Development

```bash
bundle exec rake          # Run tests + RuboCop
bundle exec rspec         # Run tests only
bundle exec rubocop       # Run linter only
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
