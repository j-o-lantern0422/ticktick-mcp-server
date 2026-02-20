# frozen_string_literal: true

RSpec.describe Ticktick::Mcp::Server::ListProjects do
  let(:client) { instance_double(Ticktick::Client) }

  before { allow(Ticktick::Client).to receive(:new).and_return(client) }

  it "returns project list as formatted JSON" do
    data = [{ "id" => "proj_001", "name" => "Work" }]
    allow(client).to receive(:list_projects).and_return(data)

    response = described_class.call
    parsed = JSON.parse(response.content.first[:text])
    expect(parsed.first["name"]).to eq("Work")
  end

  it "returns error when token is missing" do
    allow(Ticktick::Client).to receive(:new)
      .and_raise(Ticktick::Client::AuthenticationError, "Environment variable TICKTICK_ACCESS_TOKEN is not set")

    response = described_class.call
    expect(response.content.first[:text]).to include("TICKTICK_ACCESS_TOKEN")
  end

  it "returns error on API failure" do
    allow(client).to receive(:list_projects)
      .and_raise(Ticktick::Client::ApiError.new(status: 401, body: '{"error":"Unauthorized"}'))

    content = described_class.call.content.first
    expect(content[:text]).to include("API error", "401")
  end

  it "returns rate limit message when rate limited" do
    allow(client).to receive(:list_projects)
      .and_raise(Ticktick::Client::RateLimitError.new(status: 500, body: "exceed_query_limit"))

    response = described_class.call
    expect(response.content.first[:text]).to include("rate limit", "retry after 1 minute")
  end
end
