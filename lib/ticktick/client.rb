# frozen_string_literal: true

require_relative "errors"
require_relative "http_connection"
require_relative "resources/project_resource"
require_relative "resources/task_resource"
require_relative "resources/task_attributes"

module Ticktick
  class Client
    def initialize(token: ENV["TICKTICK_ACCESS_TOKEN"])
      @connection = HttpConnection.new(token: token)
      @projects   = Resources::ProjectResource.new(@connection)
      @tasks      = Resources::TaskResource.new(@connection, @projects)
    end

    def list_projects = @projects.list
    def get_project(id) = @projects.get(id)
    def get_project_data(id) = @projects.get_data(id)
    def create_project(...) = @projects.create(...)
    def update_project(id, ...) = @projects.update(id, ...)
    def list_all_tasks = @tasks.list_all

    def create_task(title:, project_id:, **opts)
      @tasks.create(Resources::TaskAttributes.new(title: title, project_id: project_id, **opts))
    end

    def update_task(task_id:, project_id:, **opts)
      @tasks.update(task_id, Resources::TaskAttributes.new(id: task_id, project_id: project_id, **opts))
    end

    def complete_task(project_id:, task_id:)
      @tasks.complete(project_id, task_id)
    end
  end
end
