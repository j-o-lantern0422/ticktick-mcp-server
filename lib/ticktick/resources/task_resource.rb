# frozen_string_literal: true

require_relative "../errors"

module Ticktick
  module Resources
    class TaskResource
      def initialize(connection, project_resource)
        @connection = connection
        @projects = project_resource
      end

      def create(task_attrs)
        @connection.post_json("task", task_attrs.to_request_body)
      end

      def list_all
        @projects.list.each_with_object([]) do |project, all_tasks|
          collect_project_tasks(project, all_tasks)
        rescue Errors::ApiError
          next
        end
      end

      private

      def collect_project_tasks(project, all_tasks)
        data = @projects.get_data(project["id"])
        (data["tasks"] || []).each do |task|
          task["project_name"] = project["name"]
          all_tasks << task
        end
      end
    end
  end
end
