# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class GetProjectData < MCP::Tool
        tool_name "get_project_data"

        description "Get project data including tasks and columns from TickTick"

        input_schema(
          properties: {
            project_id: {
              type: "string",
              description: "The ID of the project to retrieve data for"
            }
          },
          required: ["project_id"]
        )

        class << self
          include ErrorHandler

          def call(project_id:, _server_context: nil)
            data = Ticktick::Client.new.get_project_data(project_id)
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(data) }])
          rescue Ticktick::Client::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
