# ticktick-mcp-server

A Ruby gem that exposes the [TickTick Open API](https://developer.ticktick.com/) as an [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) server. This allows LLMs like Claude to manage your TickTick projects and tasks directly.

## Requirements

- Ruby >= 3.1.0
- A TickTick account with an Open API access token

## Installation

Clone the repository and install the gem locally:

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

You can obtain an access token from the TickTick Open API developer settings.

## Usage

### Claude Desktop Integration

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
