# frozen_string_literal: true

require "faraday"
require "json"
require "securerandom"
require "base64"
require_relative "callback_server"

module Ticktick
  module Auth
    class OauthFlow
      AUTHORIZE_URL = "https://ticktick.com/oauth/authorize"
      TOKEN_URL = "https://ticktick.com/oauth/token"
      SCOPE = "tasks:read tasks:write"

      Error = Class.new(StandardError)
      TimeoutError = Class.new(Error)
      DeniedError = Class.new(Error)
      NetworkError = Class.new(Error)

      def initialize(client_id:, client_secret:, port: 8585)
        @client_id = client_id
        @client_secret = client_secret
        @port = port
      end

      def run
        state = SecureRandom.hex(16)
        redirect_uri = "http://localhost:#{@port}/callback"

        puts build_authorize_message(state, redirect_uri)

        server = CallbackServer.new(port: @port)
        result = server.wait_for_code(timeout: 300)

        raise TimeoutError, "Timed out waiting for authorization. Please try again." if result.nil?
        raise DeniedError, "Authorization was denied: #{result[:error]}" if result[:error]
        raise Error, "State mismatch. Possible CSRF attack." if result[:state] != state

        exchange_code_for_token(result[:code], redirect_uri)
      end

      private

      def build_authorize_message(state, redirect_uri)
        url = build_authorize_url(state, redirect_uri)

        <<~MSG
          Open the following URL in your browser to authorize TickTick:

            #{url}

          Waiting for authorization (timeout: 5 minutes)...
        MSG
      end

      def build_authorize_url(state, redirect_uri)
        params = URI.encode_www_form(
          client_id: @client_id,
          response_type: "code",
          scope: SCOPE,
          redirect_uri: redirect_uri,
          state: state
        )
        "#{AUTHORIZE_URL}?#{params}"
      end

      def exchange_code_for_token(code, redirect_uri)
        conn = Faraday.new(url: TOKEN_URL)
        credentials = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

        response = conn.post { |req| configure_token_request(req, credentials, code, redirect_uri) }
        handle_token_response(response)
      rescue Faraday::Error => e
        raise NetworkError, "Network error during token exchange: #{e.message}"
      end

      def configure_token_request(req, credentials, code, redirect_uri)
        req.headers["Authorization"] = "Basic #{credentials}"
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.body = URI.encode_www_form(
          grant_type: "authorization_code",
          code: code,
          redirect_uri: redirect_uri
        )
      end

      def handle_token_response(response)
        raise Error, "Token exchange failed (HTTP #{response.status}): #{response.body}" unless response.success?

        data = JSON.parse(response.body)
        token = data["access_token"]
        raise Error, "No access_token in response: #{response.body}" unless token

        token
      end
    end
  end
end
