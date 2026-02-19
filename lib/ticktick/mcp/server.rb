# frozen_string_literal: true

require "mcp"
require "faraday"
require "json"
require_relative "server/version"

module Ticktick
  module Mcp
    module Server
      class Error < StandardError; end

      TICKTICK_API_BASE = "https://api.ticktick.com/open/v1"

      class ListProjects < MCP::Tool
        tool_name "list_projects"

        description "List all projects from TickTick"

        input_schema(properties: {})

        class << self
          def call(server_context: nil)
            token = ENV["TICKTICK_ACCESS_TOKEN"]
            unless token
              return MCP::Tool::Response.new(
                [{ type: "text", text: "Environment variable TICKTICK_ACCESS_TOKEN is not set" }],
                error: true
              )
            end

            conn = Faraday.new(url: TICKTICK_API_BASE) do |f|
              f.request :authorization, "Bearer", token
            end

            response = conn.get("project")

            if response.success?
              projects = JSON.parse(response.body)
              MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(projects) }])
            else
              MCP::Tool::Response.new(
                [{ type: "text", text: "Authentication failed (HTTP #{response.status}): #{response.body}" }],
                error: true
              )
            end
          rescue StandardError => e
            MCP::Tool::Response.new(
              [{ type: "text", text: "API request error: #{e.message}" }],
              error: true
            )
          end
        end
      end

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
          def call(project_id:, server_context: nil)
            token = ENV["TICKTICK_ACCESS_TOKEN"]
            unless token
              return MCP::Tool::Response.new(
                [{ type: "text", text: "Environment variable TICKTICK_ACCESS_TOKEN is not set" }],
                error: true
              )
            end

            conn = Faraday.new(url: TICKTICK_API_BASE) do |f|
              f.request :authorization, "Bearer", token
            end

            response = conn.get("project/#{project_id}/data")

            if response.success?
              data = JSON.parse(response.body)
              MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(data) }])
            else
              MCP::Tool::Response.new(
                [{ type: "text", text: "Authentication failed (HTTP #{response.status}): #{response.body}" }],
                error: true
              )
            end
          rescue StandardError => e
            MCP::Tool::Response.new(
              [{ type: "text", text: "API request error: #{e.message}" }],
              error: true
            )
          end
        end
      end

      class ListAllTasks < MCP::Tool
        tool_name "list_all_tasks"

        description "List all tasks across all projects from TickTick"

        input_schema(properties: {})

        class << self
          def call(server_context: nil)
            token = ENV["TICKTICK_ACCESS_TOKEN"]
            unless token
              return MCP::Tool::Response.new(
                [{ type: "text", text: "Environment variable TICKTICK_ACCESS_TOKEN is not set" }],
                error: true
              )
            end

            conn = Faraday.new(url: TICKTICK_API_BASE) do |f|
              f.request :authorization, "Bearer", token
            end

            projects_response = conn.get("project")
            return fetch_projects_error(projects_response) unless projects_response.success?

            all_tasks = collect_tasks(conn, JSON.parse(projects_response.body))
            MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(all_tasks) }])
          rescue StandardError => e
            MCP::Tool::Response.new(
              [{ type: "text", text: "API request error: #{e.message}" }],
              error: true
            )
          end

          private

          def fetch_projects_error(response)
            message = "Failed to fetch projects (HTTP #{response.status}): " \
                      "#{response.body}"
            MCP::Tool::Response.new([{ type: "text", text: message }], error: true)
          end

          def collect_tasks(conn, projects)
            projects.each_with_object([]) do |project, all_tasks|
              data_response = conn.get("project/#{project["id"]}/data")
              next unless data_response.success?

              tasks = JSON.parse(data_response.body)["tasks"] || []
              tasks.each do |task|
                task["project_name"] = project["name"]
                all_tasks << task
              end
            end
          end
        end
      end

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
