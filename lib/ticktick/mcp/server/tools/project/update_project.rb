# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class UpdateProject < MCP::Tool
        tool_name "update_project"

        description "Update an existing TickTick project's metadata"

        input_schema(
          properties: {
            project_id: {
              type: "string",
              description: "The ID of the project to update"
            },
            name: {
              type: "string",
              description: "New name of the project"
            },
            color: {
              type: "string",
              description: 'New color of the project, e.g. "#F18181"'
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
          required: ["project_id"]
        )

        class << self
          include ErrorHandler

          def call(project_id:, name: nil, color: nil, sort_order: nil,
                   view_mode: nil, kind: nil, _server_context: nil, **)
            client = Ticktick::Client.new
            project = client.update_project(
              project_id,
              name: name, color: color,
              sort_order: sort_order, view_mode: view_mode, kind: kind
            )
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(project) }])
          rescue Ticktick::Errors::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
