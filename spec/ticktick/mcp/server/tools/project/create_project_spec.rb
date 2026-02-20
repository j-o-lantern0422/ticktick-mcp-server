# frozen_string_literal: true

RSpec.describe Ticktick::Mcp::Server::CreateProject do
  let(:client) { instance_double(Ticktick::Client) }

  before { allow(Ticktick::Client).to receive(:new).and_return(client) }

  it "returns created project as formatted JSON" do
    project = { "id" => "proj_new", "name" => "Work", "color" => "#F18181", "kind" => "TASK" }
    allow(client).to receive(:create_project)
      .with(name: "Work", color: "#F18181", sort_order: nil, view_mode: nil, kind: nil)
      .and_return(project)

    parsed = JSON.parse(described_class.call(name: "Work", color: "#F18181").content.first[:text])
    expect(parsed["name"]).to eq("Work")
    expect(parsed["color"]).to eq("#F18181")
  end

  it "passes all optional parameters to the client" do
    project = { "id" => "proj_new", "name" => "Notes" }
    allow(client).to receive(:create_project)
      .with(name: "Notes", color: nil, sort_order: 10, view_mode: "kanban", kind: "NOTE")
      .and_return(project)

    response = described_class.call(name: "Notes", sort_order: 10, view_mode: "kanban", kind: "NOTE")
    parsed = JSON.parse(response.content.first[:text])
    expect(parsed["name"]).to eq("Notes")
  end

  it "returns error when token is missing" do
    allow(Ticktick::Client).to receive(:new)
      .and_raise(Ticktick::Client::AuthenticationError, "Environment variable TICKTICK_ACCESS_TOKEN is not set")

    response = described_class.call(name: "Test")
    expect(response.content.first[:text]).to include("TICKTICK_ACCESS_TOKEN")
  end

  it "returns error on API failure" do
    allow(client).to receive(:create_project)
      .and_raise(Ticktick::Client::ApiError.new(status: 400, body: '{"error":"Bad Request"}'))

    content = described_class.call(name: "Bad").content.first
    expect(content[:text]).to include("API error", "400")
  end

  it "returns rate limit message when rate limited" do
    allow(client).to receive(:create_project)
      .and_raise(Ticktick::Client::RateLimitError.new(status: 500, body: "exceed_query_limit"))

    response = described_class.call(name: "Test")
    expect(response.content.first[:text]).to include("rate limit", "retry after 1 minute")
  end
end
