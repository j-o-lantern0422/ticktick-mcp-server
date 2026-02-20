# frozen_string_literal: true

require "mcp"
require_relative "../../ticktick/client"
require_relative "server/version"
require_relative "server/tools/project/list_projects"
require_relative "server/tools/project/get_project"
require_relative "server/tools/project/get_project_data"
require_relative "server/tools/task/list_all_tasks"
require_relative "server/tools/task/create_task"
require_relative "server/tools/project/create_project"
require_relative "server/tools/project/update_project"

module Ticktick
  module Mcp
    module Server
      class Error < StandardError; end

      def self.build
        MCP::Server.new(
          name: "ticktick-mcp-server",
          version: VERSION,
          tools: [ListProjects, GetProject, GetProjectData, ListAllTasks, CreateTask, CreateProject, UpdateProject]
        )
      end
    end
  end
end
