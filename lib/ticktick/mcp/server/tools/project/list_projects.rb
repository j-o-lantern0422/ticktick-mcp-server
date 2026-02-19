# frozen_string_literal: true

require "mcp"

module Ticktick
  module Mcp
    module Server
      class ListProjects < MCP::Tool
        tool_name "list_projects"

        description "List all projects from TickTick"

        input_schema(properties: {})

        class << self
          def call(_server_context: nil)
            data = Ticktick::Client.new.list_projects
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
