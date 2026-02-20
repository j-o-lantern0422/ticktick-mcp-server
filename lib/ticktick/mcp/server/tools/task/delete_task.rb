# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class DeleteTask < MCP::Tool
        tool_name "delete_task"

        description "Delete a task in TickTick"

        input_schema(
          properties: {
            project_id: { type: "string", description: "Project ID the task belongs to (required)" },
            task_id: { type: "string", description: "Task ID to delete (required)" }
          },
          required: %w[project_id task_id]
        )

        class << self
          include ErrorHandler

          def call(project_id:, task_id:, _server_context: nil, **)
            Ticktick::Client.new.delete_task(project_id: project_id, task_id: task_id)
            MCP::Tool::Response.new([{ type: "text", text: "Task #{task_id} deleted." }])
          rescue Ticktick::Errors::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
