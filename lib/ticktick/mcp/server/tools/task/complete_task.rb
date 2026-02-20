# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class CompleteTask < MCP::Tool
        tool_name "complete_task"

        description "Mark a task as complete in TickTick"

        input_schema(
          properties: {
            project_id: { type: "string", description: "Project ID the task belongs to (required)" },
            task_id: { type: "string", description: "Task ID to complete (required)" }
          },
          required: %w[project_id task_id]
        )

        class << self
          include ErrorHandler

          def call(project_id:, task_id:, _server_context: nil, **)
            Ticktick::Client.new.complete_task(project_id: project_id, task_id: task_id)
            MCP::Tool::Response.new([{ type: "text", text: "Task #{task_id} marked as complete." }])
          rescue Ticktick::Errors::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
