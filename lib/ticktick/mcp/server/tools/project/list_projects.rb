# frozen_string_literal: true

require "mcp"
require_relative "../../error_handler"

module Ticktick
  module Mcp
    module Server
      class ListProjects < MCP::Tool
        tool_name "list_projects"

        description "List all projects from TickTick"

        input_schema(properties: {})

        class << self
          include ErrorHandler

          def call(_server_context: nil)
            data = Ticktick::Client.new.list_projects
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(data) }])
          rescue Ticktick::Errors::Error, StandardError => e
            handle_client_error(e)
          end
        end
      end
    end
  end
end
