# frozen_string_literal: true

require "mcp"
require_relative "../../ticktick/client"
require_relative "server/version"
require_relative "server/tools/project/list_projects"
require_relative "server/tools/project/get_project_data"
require_relative "server/tools/task/list_all_tasks"

module Ticktick
  module Mcp
    module Server
      class Error < StandardError; end

      def self.build
        MCP::Server.new(
          name: "ticktick-mcp-server",
          version: VERSION,
          tools: [ListProjects, GetProjectData, ListAllTasks]
        )
      end
    end
  end
end
