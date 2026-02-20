# frozen_string_literal: true

module Ticktick
  module Mcp
    module Server
      module ErrorHandler
        RATE_LIMIT_MESSAGE = "TickTick API rate limit reached (max 100 requests/min). Please retry after 1 minute."

        def error_response(text)
          MCP::Tool::Response.new([{ type: "text", text: text }], error: true)
        end

        def handle_client_error(error)
          case error
          when Ticktick::Errors::AuthenticationError
            error_response(error.message)
          when Ticktick::Errors::RateLimitError
            error_response(RATE_LIMIT_MESSAGE)
          when Ticktick::Errors::ApiError
            error_response("API error (HTTP #{error.status}): #{error.body}")
          else
            error_response("API request error: #{error.message}")
          end
        end
      end
    end
  end
end
