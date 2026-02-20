# frozen_string_literal: true

RSpec.describe Ticktick::HttpConnection do
  describe ".new" do
    it "raises AuthenticationError when token is nil" do
      expect { described_class.new(token: nil) }
        .to raise_error(Ticktick::Errors::AuthenticationError, /TICKTICK_ACCESS_TOKEN/)
    end
  end

  describe "#get" do
    subject(:conn) { described_class.new(token: "valid_token") }

    it "returns parsed JSON on success" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .with(headers: { "Authorization" => "Bearer valid_token" })
        .to_return(status: 200, body: [{ "id" => "proj_001", "name" => "Work" }].to_json)

      result = conn.get("project")
      expect(result).to eq([{ "id" => "proj_001", "name" => "Work" }])
    end

    it "raises ApiError on HTTP error" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 401, body: '{"error":"Unauthorized"}')

      expect { conn.get("project") }
        .to raise_error(Ticktick::Errors::ApiError) { |e|
          expect(e.status).to eq(401)
          expect(e.body).to include("Unauthorized")
        }
    end

    it "raises RateLimitError when rate limited" do
      rate_limit_body = { "errorCode" => "exceed_query_limit" }.to_json
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 500, body: rate_limit_body)

      expect { conn.get("project") }
        .to raise_error(Ticktick::Errors::RateLimitError) { |e|
          expect(e.status).to eq(500)
          expect(e.body).to include("exceed_query_limit")
        }
    end

    it "raises plain ApiError for non-rate-limit 500 errors" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 500, body: '{"errorCode":"internal_error"}')

      expect { conn.get("project") }
        .to raise_error(Ticktick::Errors::ApiError) { |e|
          expect(e).not_to be_a(Ticktick::Errors::RateLimitError)
        }
    end

    it "raises plain ApiError for non-JSON error responses" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 500, body: "Internal Server Error")

      expect { conn.get("project") }
        .to raise_error(Ticktick::Errors::ApiError) { |e|
          expect(e).not_to be_a(Ticktick::Errors::RateLimitError)
        }
    end
  end

  describe "#delete" do
    subject(:conn) { described_class.new(token: "valid_token") }

    it "returns nil on 200 with empty body" do
      stub_request(:delete, "https://api.ticktick.com/open/v1/project/proj_001/task/task_001")
        .with(headers: { "Authorization" => "Bearer valid_token" })
        .to_return(status: 200, body: "")

      result = conn.delete("project/proj_001/task/task_001")
      expect(result).to be_nil
    end

    it "raises ApiError on HTTP error" do
      stub_request(:delete, "https://api.ticktick.com/open/v1/project/proj_001/task/task_001")
        .to_return(status: 404, body: '{"error":"Not Found"}')

      expect { conn.delete("project/proj_001/task/task_001") }
        .to raise_error(Ticktick::Errors::ApiError) { |e| expect(e.status).to eq(404) }
    end

    it "raises RateLimitError when rate limited" do
      rate_limit_body = { "errorCode" => "exceed_query_limit" }.to_json
      stub_request(:delete, "https://api.ticktick.com/open/v1/project/proj_001/task/task_001")
        .to_return(status: 500, body: rate_limit_body)

      expect { conn.delete("project/proj_001/task/task_001") }
        .to raise_error(Ticktick::Errors::RateLimitError)
    end
  end

  describe "#post_json" do
    subject(:conn) { described_class.new(token: "valid_token") }

    it "sends JSON body with Content-Type header and returns parsed response" do
      body = { name: "New Project" }
      created = { "id" => "proj_new", "name" => "New Project" }
      stub_request(:post, "https://api.ticktick.com/open/v1/project")
        .with(
          headers: { "Authorization" => "Bearer valid_token", "Content-Type" => "application/json" },
          body: body.to_json
        )
        .to_return(status: 200, body: created.to_json)

      result = conn.post_json("project", body)
      expect(result["id"]).to eq("proj_new")
    end

    it "raises RateLimitError when rate limited" do
      rate_limit_body = { "errorCode" => "exceed_query_limit" }.to_json
      stub_request(:post, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 500, body: rate_limit_body)

      expect { conn.post_json("project", { name: "Test" }) }
        .to raise_error(Ticktick::Errors::RateLimitError)
    end

    it "raises ApiError on HTTP error" do
      stub_request(:post, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 400, body: '{"error":"Bad Request"}')

      expect { conn.post_json("project", { name: "Bad" }) }
        .to raise_error(Ticktick::Errors::ApiError) { |e| expect(e.status).to eq(400) }
    end
  end
end
