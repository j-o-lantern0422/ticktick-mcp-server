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

      class TestAuth < MCP::Tool
        tool_name "test_auth"

        description "Test authentication with the TickTick API and return user information"

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

            response = conn.get("user")

            if response.success?
              user_data = JSON.parse(response.body)
              MCP::Tool::Response.new([{ type: "text", text: JSON.pretty_generate(user_data) }])
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

      def self.build
        MCP::Server.new(
          name: "ticktick-mcp-server",
          version: VERSION,
          tools: [TestAuth]
        )
      end
    end
  end
end
