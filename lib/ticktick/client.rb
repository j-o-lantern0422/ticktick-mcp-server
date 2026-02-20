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

    def get_project_data(project_id)
      response = @connection.get("project/#{project_id}/data")
      handle_response(response)
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
