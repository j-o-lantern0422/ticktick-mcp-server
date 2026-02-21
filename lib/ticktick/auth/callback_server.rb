# frozen_string_literal: true

require "webrick"

module Ticktick
  module Auth
    class CallbackServer
      CALLBACK_PATH = "/callback"
      SUCCESS_HTML = <<~HTML
        <!DOCTYPE html>
        <html>
          <head><meta charset="utf-8"><title>TickTick Authorization</title></head>
          <body>
            <h1>Authorization successful!</h1>
            <p>You can close this browser tab and return to the terminal.</p>
          </body>
        </html>
      HTML
      ERROR_HTML = <<~HTML
        <!DOCTYPE html>
        <html>
          <head><meta charset="utf-8"><title>TickTick Authorization</title></head>
          <body>
            <h1>Authorization failed</h1>
            <p>Access was denied. Please try again.</p>
          </body>
        </html>
      HTML

      def initialize(port:)
        @port = port
        @queue = Queue.new
      end

      def wait_for_code(timeout: 300)
        server = build_server
        server_thread = Thread.new { server.start }

        result = poll_for_result(timeout)
        server.shutdown
        server_thread.join(5)
        result
      end

      private

      def build_server
        logger = WEBrick::Log.new(nil, WEBrick::Log::FATAL)
        access_log = [[nil, ""]]

        server = WEBrick::HTTPServer.new(
          Port: @port,
          Logger: logger,
          AccessLog: access_log
        )
        server.mount_proc(CALLBACK_PATH) { |req, res| handle_callback(req, res) }
        server
      end

      def handle_callback(req, res)
        code = req.query["code"]
        error = req.query["error"]
        state = req.query["state"]

        if code
          @queue.push({ code: code, state: state })
          write_response(res, SUCCESS_HTML)
        else
          @queue.push({ error: error || "unknown_error" })
          write_response(res, ERROR_HTML)
        end
      end

      def write_response(res, html)
        res.status = 200
        res.content_type = "text/html; charset=utf-8"
        res.body = html
      end

      def poll_for_result(timeout)
        deadline = Time.now + timeout
        loop do
          return @queue.pop(true) unless @queue.empty?
          return nil if Time.now >= deadline

          sleep 0.1
        end
      end
    end
  end
end
