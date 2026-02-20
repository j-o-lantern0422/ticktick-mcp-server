# frozen_string_literal: true

RSpec.describe Ticktick::Mcp::Server::UpdateProject do
  let(:client) { instance_double(Ticktick::Client) }

  before { allow(Ticktick::Client).to receive(:new).and_return(client) }

  it "returns updated project as formatted JSON" do
    project = { "id" => "proj_001", "name" => "Renamed", "color" => "#F18181" }
    allow(client).to receive(:update_project)
      .with("proj_001", name: "Renamed", color: "#F18181", sort_order: nil, view_mode: nil, kind: nil)
      .and_return(project)

    response = described_class.call(project_id: "proj_001", name: "Renamed", color: "#F18181")
    parsed = JSON.parse(response.content.first[:text])
    expect(parsed["name"]).to eq("Renamed")
    expect(parsed["color"]).to eq("#F18181")
  end

  it "passes all optional parameters to the client" do
    project = { "id" => "proj_001", "name" => "Notes", "viewMode" => "kanban", "kind" => "NOTE" }
    allow(client).to receive(:update_project)
      .with("proj_001", name: nil, color: nil, sort_order: 10, view_mode: "kanban", kind: "NOTE")
      .and_return(project)

    response = described_class.call(project_id: "proj_001", sort_order: 10, view_mode: "kanban", kind: "NOTE")
    parsed = JSON.parse(response.content.first[:text])
    expect(parsed["viewMode"]).to eq("kanban")
  end

  it "returns error when token is missing" do
    allow(Ticktick::Client).to receive(:new)
      .and_raise(Ticktick::Errors::AuthenticationError, "Environment variable TICKTICK_ACCESS_TOKEN is not set")

    response = described_class.call(project_id: "proj_001")
    expect(response.content.first[:text]).to include("TICKTICK_ACCESS_TOKEN")
  end

  it "returns error on API failure" do
    allow(client).to receive(:update_project)
      .and_raise(Ticktick::Errors::ApiError.new(status: 400, body: '{"error":"Bad Request"}'))

    content = described_class.call(project_id: "proj_001", name: "Bad").content.first
    expect(content[:text]).to include("API error", "400")
  end

  it "returns rate limit message when rate limited" do
    allow(client).to receive(:update_project)
      .and_raise(Ticktick::Errors::RateLimitError.new(status: 500, body: "exceed_query_limit"))

    response = described_class.call(project_id: "proj_001", name: "Test")
    expect(response.content.first[:text]).to include("rate limit", "retry after 1 minute")
  end
end
