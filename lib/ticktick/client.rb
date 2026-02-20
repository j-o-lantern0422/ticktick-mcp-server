# frozen_string_literal: true

require "faraday"
require "json"

module Ticktick
  class Client
    class Error < StandardError; end

    class AuthenticationError < Error; end

    class ApiError < Error
      attr_reader :status, :body

      def initialize(status:, body:)
        @status = status
        @body = body
        super("HTTP #{status}: #{body}")
      end
    end

    class RateLimitError < ApiError; end

    API_BASE = "https://api.ticktick.com/open/v1"
    RATE_LIMIT_ERROR_CODE = "exceed_query_limit"

    def initialize(token: ENV["TICKTICK_ACCESS_TOKEN"])
      raise AuthenticationError, "Environment variable TICKTICK_ACCESS_TOKEN is not set" unless token

      @connection = Faraday.new(url: API_BASE) do |f|
        f.request :authorization, "Bearer", token
      end
    end

    def list_projects
      response = @connection.get("project")
      handle_response(response)
    end

    def get_project(project_id)
      response = @connection.get("project/#{project_id}")
      handle_response(response)
    end

    def get_project_data(project_id)
      response = @connection.get("project/#{project_id}/data")
      handle_response(response)
    end

    def create_project(name:, color: nil, sort_order: nil, view_mode: nil, kind: nil)
      body = { name: name }
      body[:color] = color if color
      body[:sortOrder] = sort_order if sort_order
      body[:viewMode] = view_mode if view_mode
      body[:kind] = kind if kind

      response = @connection.post("project") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json
      end
      handle_response(response)
    end

    def update_project(project_id, name: nil, color: nil, sort_order: nil, view_mode: nil, kind: nil)
      body = { name: name, color: color, sortOrder: sort_order, viewMode: view_mode, kind: kind }.compact

      response = @connection.post("project/#{project_id}") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json
      end
      handle_response(response)
    end

    def create_task(title:, project_id:, content: nil, desc: nil,
                    is_all_day: nil, start_date: nil, due_date: nil,
                    time_zone: nil, reminders: nil, repeat_flag: nil,
                    priority: nil, sort_order: nil, items: nil)
      body = build_task_body(
        title: title, project_id: project_id, content: content, desc: desc,
        is_all_day: is_all_day, start_date: start_date, due_date: due_date,
        time_zone: time_zone, reminders: reminders, repeat_flag: repeat_flag,
        priority: priority, sort_order: sort_order, items: items
      )
      handle_response(post_json("task", body))
    end

    def list_all_tasks
      list_projects.each_with_object([]) do |project, all_tasks|
        collect_project_tasks(project, all_tasks)
      rescue ApiError
        next
      end
    end

    private

    def collect_project_tasks(project, all_tasks)
      data = get_project_data(project["id"])
      (data["tasks"] || []).each do |task|
        task["project_name"] = project["name"]
        all_tasks << task
      end
    end

    def post_json(path, body)
      @connection.post(path) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json
      end
    end

    def build_task_body(title:, project_id:, content:, desc:, is_all_day:,
                        start_date:, due_date:, time_zone:, reminders:,
                        repeat_flag:, priority:, sort_order:, items:)
      {
        title: title, projectId: project_id, content: content,
        desc: desc, isAllDay: is_all_day, startDate: start_date,
        dueDate: due_date, timeZone: time_zone, reminders: reminders,
        repeatFlag: repeat_flag, priority: priority,
        sortOrder: sort_order, items: items
      }.compact
    end

    def handle_response(response)
      unless response.success?
        raise_rate_limit_error!(response) if rate_limit_error?(response)
        raise ApiError.new(status: response.status, body: response.body)
      end

      JSON.parse(response.body)
    end

    def rate_limit_error?(response)
      parsed = JSON.parse(response.body)
      parsed["errorCode"] == RATE_LIMIT_ERROR_CODE
    rescue JSON::ParserError
      false
    end

    def raise_rate_limit_error!(response)
      raise RateLimitError.new(status: response.status, body: response.body)
    end
  end
end
