# frozen_string_literal: true

module Ticktick
  module Errors
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
  end
end
