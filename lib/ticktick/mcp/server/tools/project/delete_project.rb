# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class DeleteProject < MCP::Tool
        tool_name "delete_project"

        description "Delete a project in TickTick"

        input_schema(
          properties: {
            project_id: { type: "string", description: "The ID of the project to delete (required)" }
          },
          required: %w[project_id]
        )

        class << self
          include ErrorHandler

          def call(project_id:, _server_context: nil, **)
            Ticktick::Client.new.delete_project(project_id: project_id)
            MCP::Tool::Response.new([{ type: "text", text: "Project #{project_id} deleted." }])
          rescue Ticktick::Errors::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
