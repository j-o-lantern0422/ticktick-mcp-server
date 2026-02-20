# frozen_string_literal: true

require "faraday"
require "json"
require_relative "errors"

module Ticktick
  class HttpConnection
    API_BASE = "https://api.ticktick.com/open/v1"
    RATE_LIMIT_ERROR_CODE = "exceed_query_limit"

    def initialize(token:)
      raise Errors::AuthenticationError, "Environment variable TICKTICK_ACCESS_TOKEN is not set" unless token

      @conn = Faraday.new(url: API_BASE) do |f|
        f.request :authorization, "Bearer", token
      end
    end

    def get(path)
      handle_response(@conn.get(path))
    end

    def post(path)
      handle_response(@conn.post(path))
    end

    def delete(path)
      handle_response(@conn.delete(path))
    end

    def post_json(path, body)
      response = @conn.post(path) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = body.to_json
      end
      handle_response(response)
    end

    private

    def handle_response(response)
      unless response.success?
        raise_rate_limit_error!(response) if rate_limit_error?(response)
        raise Errors::ApiError.new(status: response.status, body: response.body)
      end

      return nil if response.body.nil? || response.body.empty?

      JSON.parse(response.body)
    end

    def rate_limit_error?(response)
      parsed = JSON.parse(response.body)
      parsed["errorCode"] == RATE_LIMIT_ERROR_CODE
    rescue JSON::ParserError
      false
    end

    def raise_rate_limit_error!(response)
      raise Errors::RateLimitError.new(status: response.status, body: response.body)
    end
  end
end
