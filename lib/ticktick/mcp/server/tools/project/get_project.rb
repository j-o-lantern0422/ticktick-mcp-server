# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class GetProject < MCP::Tool
        tool_name "get_project"

        description "Get a project by ID from TickTick"

        input_schema(
          properties: {
            project_id: {
              type: "string",
              description: "The ID of the project to retrieve"
            }
          },
          required: ["project_id"]
        )

        class << self
          include ErrorHandler

          def call(project_id:, _server_context: nil)
            data = Ticktick::Client.new.get_project(project_id)
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(data) }])
          rescue Ticktick::Errors::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
