# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class UpdateTask < MCP::Tool
        tool_name "update_task"

        description "Update an existing task in TickTick"

        input_schema(
          properties: {
            task_id: { type: "string", description: "Task ID to update (required)" },
            project_id: { type: "string", description: "Project ID the task belongs to (required)" },
            title: { type: "string", description: "Task title" },
            content: { type: "string", description: "Task content" },
            desc: { type: "string", description: "Description of checklist" },
            is_all_day: { type: "boolean", description: "All day task" },
            start_date: {
              type: "string",
              description: 'Start date in "yyyy-MM-dd\'T\'HH:mm:ssZ" format, e.g. "2019-11-13T03:00:00+0000"'
            },
            due_date: {
              type: "string",
              description: 'Due date in "yyyy-MM-dd\'T\'HH:mm:ssZ" format, e.g. "2019-11-13T03:00:00+0000"'
            },
            time_zone: { type: "string", description: 'Time zone, e.g. "America/Los_Angeles"' },
            reminders: {
              type: "array",
              items: { type: "string" },
              description: 'List of reminders, e.g. ["TRIGGER:P0DT9H0M0S"]'
            },
            repeat_flag: {
              type: "string",
              description: 'Recurring rule, e.g. "RRULE:FREQ=DAILY;INTERVAL=1"'
            },
            priority: {
              type: "integer",
              description: "Priority (0: none, 1: low, 3: medium, 5: high)"
            },
            sort_order: { type: "integer", description: "Sort order of the task" },
            items: {
              type: "array",
              description: "List of subtasks",
              items: {
                type: "object",
                properties: {
                  title: { type: "string" },
                  start_date: { type: "string" },
                  is_all_day: { type: "boolean" },
                  sort_order: { type: "integer" },
                  time_zone: { type: "string" },
                  status: { type: "integer" }
                }
              }
            }
          },
          required: %w[task_id project_id]
        )

        class << self
          include ErrorHandler

          # rubocop:disable Metrics/ParameterLists
          def call(task_id:, project_id:, title: nil, content: nil, desc: nil,
                   is_all_day: nil, start_date: nil, due_date: nil,
                   time_zone: nil, reminders: nil, repeat_flag: nil,
                   priority: nil, sort_order: nil, items: nil,
                   _server_context: nil, **)
            # rubocop:enable Metrics/ParameterLists
            task = Ticktick::Client.new.update_task(
              task_id: task_id, project_id: project_id, title: title, content: content, desc: desc,
              is_all_day: is_all_day, start_date: start_date, due_date: due_date,
              time_zone: time_zone, reminders: reminders, repeat_flag: repeat_flag,
              priority: priority, sort_order: sort_order, items: items
            )
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(task) }])
          rescue Ticktick::Errors::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
