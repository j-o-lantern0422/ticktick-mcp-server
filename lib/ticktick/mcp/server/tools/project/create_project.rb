# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class CreateProject < MCP::Tool
        tool_name "create_project"

        description "Create a new TickTick project"

        input_schema(
          properties: {
            name: {
              type: "string",
              description: "Name of the project (required)"
            },
            color: {
              type: "string",
              description: 'Color of the project, e.g. "#F18181"'
            },
            sort_order: {
              type: "integer",
              description: "Sort order value of the project"
            },
            view_mode: {
              type: "string",
              description: 'View mode: "list", "kanban", or "timeline"'
            },
            kind: {
              type: "string",
              description: 'Project kind: "TASK" or "NOTE"'
            }
          },
          required: ["name"]
        )

        class << self
          include ErrorHandler

          def call(name:, color: nil, sort_order: nil, view_mode: nil, kind: nil, _server_context: nil, **)
            project = Ticktick::Client.new.create_project(
              name: name,
              color: color,
              sort_order: sort_order,
              view_mode: view_mode,
              kind: kind
            )
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(project) }])
          rescue Ticktick::Client::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
