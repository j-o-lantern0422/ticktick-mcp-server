# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class ListAllTasks < MCP::Tool
        tool_name "list_all_tasks"

        description "List all tasks across all projects from TickTick"

        input_schema(properties: {})

        class << self
          include ErrorHandler

          def call(_server_context: nil)
            tasks = Ticktick::Client.new.list_all_tasks
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(tasks) }])
          rescue Ticktick::Client::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
