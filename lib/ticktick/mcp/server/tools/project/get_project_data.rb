# frozen_string_literal: true

require "mcp"

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
          def call(project_id:, _server_context: nil)
            data = Ticktick::Client.new.get_project_data(project_id)
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(data) }])
          rescue Ticktick::Client::AuthenticationError => e
            MCP::Tool::Response.new([{ type: "text", text: e.message }], error: true)
          rescue Ticktick::Client::ApiError => e
            MCP::Tool::Response.new(
              [{ type: "text", text: "Authentication failed (HTTP #{e.status}): #{e.body}" }], error: true
            )
          rescue StandardError => e
            MCP::Tool::Response.new([{ type: "text", text: "API request error: #{e.message}" }], error: true)
          end
        end
      end
    end
  end
end
