# frozen_string_literal: true

RSpec.describe Ticktick::Mcp::Server do
  it "has a version number" do
    expect(Ticktick::Mcp::Server::VERSION).not_to be nil
  end

  describe ".build" do
    it "returns an MCP::Server instance" do
      server = described_class.build
      expect(server).to be_a(MCP::Server)
    end
  end

  describe Ticktick::Mcp::Server::TestAuth do
    let(:user_response_body) do
      {
        "profile_id" => "abc123",
        "inbox_id" => "inbox_001",
        "username" => "testuser",
        "time_zone" => "Asia/Tokyo"
      }.to_json
    end

    context "when TICKTICK_ACCESS_TOKEN is not set" do
      before { ENV.delete("TICKTICK_ACCESS_TOKEN") }

      it "returns an error response" do
        response = described_class.call
        expect(response).to be_a(MCP::Tool::Response)
        content = response.content.first
        expect(content[:type]).to eq("text")
        expect(content[:text]).to include("TICKTICK_ACCESS_TOKEN")
      end
    end

    context "when authentication succeeds" do
      before { ENV["TICKTICK_ACCESS_TOKEN"] = "valid_token" }
      after { ENV.delete("TICKTICK_ACCESS_TOKEN") }

      it "returns user information" do
        stub_request(:get, "https://api.ticktick.com/open/v1/user")
          .with(headers: { "Authorization" => "Bearer valid_token" })
          .to_return(status: 200, body: user_response_body, headers: { "Content-Type" => "application/json" })

        response = described_class.call
        expect(response).to be_a(MCP::Tool::Response)
        content = response.content.first
        expect(content[:type]).to eq("text")

        parsed = JSON.parse(content[:text])
        expect(parsed["username"]).to eq("testuser")
        expect(parsed["time_zone"]).to eq("Asia/Tokyo")
      end
    end

    context "when authentication fails" do
      before { ENV["TICKTICK_ACCESS_TOKEN"] = "invalid_token" }
      after { ENV.delete("TICKTICK_ACCESS_TOKEN") }

      it "returns an error response" do
        stub_request(:get, "https://api.ticktick.com/open/v1/user")
          .with(headers: { "Authorization" => "Bearer invalid_token" })
          .to_return(status: 401, body: '{"error":"Unauthorized"}')

        response = described_class.call
        content = response.content.first
        expect(content[:text]).to include("Authentication failed")
        expect(content[:text]).to include("401")
      end
    end
  end
end
