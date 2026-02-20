# frozen_string_literal: true

RSpec.describe Ticktick::Mcp::Server::GetProjectData do
  let(:client) { instance_double(Ticktick::Client) }

  before { allow(Ticktick::Client).to receive(:new).and_return(client) }

  it "returns project data as formatted JSON" do
    data = {
      "project" => { "id" => "proj_001", "name" => "Work" },
      "tasks" => [{ "id" => "task_001", "title" => "Buy groceries" }],
      "columns" => [{ "id" => "col_001", "name" => "To Do" }]
    }
    allow(client).to receive(:get_project_data).with("proj_001").and_return(data)

    parsed = JSON.parse(described_class.call(project_id: "proj_001").content.first[:text])
    expect(parsed["project"]["name"]).to eq("Work")
    expect(parsed["tasks"].first["title"]).to eq("Buy groceries")
  end

  it "returns error when token is missing" do
    allow(Ticktick::Client).to receive(:new)
      .and_raise(Ticktick::Errors::AuthenticationError, "Environment variable TICKTICK_ACCESS_TOKEN is not set")

    response = described_class.call(project_id: "proj_001")
    expect(response.content.first[:text]).to include("TICKTICK_ACCESS_TOKEN")
  end

  it "returns error on API failure" do
    allow(client).to receive(:get_project_data)
      .with("proj_001")
      .and_raise(Ticktick::Errors::ApiError.new(status: 401, body: '{"error":"Unauthorized"}'))

    content = described_class.call(project_id: "proj_001").content.first
    expect(content[:text]).to include("API error", "401")
  end

  it "returns rate limit message when rate limited" do
    allow(client).to receive(:get_project_data)
      .with("proj_001")
      .and_raise(Ticktick::Errors::RateLimitError.new(status: 500, body: "exceed_query_limit"))

    response = described_class.call(project_id: "proj_001")
    expect(response.content.first[:text]).to include("rate limit", "retry after 1 minute")
  end
end
