# frozen_string_literal: true

require "mcp"

module Ticktick
  module Mcp
    module Server
      class ListAllTasks < MCP::Tool
        tool_name "list_all_tasks"

        description "List all tasks across all projects from TickTick"

        input_schema(properties: {})

        class << self
          def call(_server_context: nil)
            tasks = Ticktick::Client.new.list_all_tasks
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(tasks) }])
          rescue Ticktick::Client::AuthenticationError => e
            MCP::Tool::Response.new([{ type: "text", text: e.message }], error: true)
          rescue Ticktick::Client::ApiError => e
            MCP::Tool::Response.new(
              [{ type: "text", text: "Failed to fetch projects (HTTP #{e.status}): #{e.body}" }], error: true
            )
          rescue StandardError => e
            MCP::Tool::Response.new([{ type: "text", text: "API request error: #{e.message}" }], error: true)
          end
        end
      end
    end
  end
end
