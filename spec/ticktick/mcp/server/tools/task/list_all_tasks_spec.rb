# frozen_string_literal: true

RSpec.describe Ticktick::Mcp::Server::ListAllTasks do
  let(:client) { instance_double(Ticktick::Client) }

  before { allow(Ticktick::Client).to receive(:new).and_return(client) }

  it "returns all tasks as formatted JSON" do
    tasks = [
      { "id" => "t1", "title" => "Fix bug", "project_name" => "Work" },
      { "id" => "t3", "title" => "Buy groceries", "project_name" => "Personal" }
    ]
    allow(client).to receive(:list_all_tasks).and_return(tasks)

    parsed = JSON.parse(described_class.call.content.first[:text])
    expect(parsed.length).to eq(2)
    expect(parsed[0]).to include("project_name" => "Work", "title" => "Fix bug")
  end

  it "returns error when token is missing" do
    allow(Ticktick::Client).to receive(:new)
      .and_raise(Ticktick::Errors::AuthenticationError, "Environment variable TICKTICK_ACCESS_TOKEN is not set")

    response = described_class.call
    expect(response.content.first[:text]).to include("TICKTICK_ACCESS_TOKEN")
  end

  it "returns error when project list fetch fails" do
    allow(client).to receive(:list_all_tasks)
      .and_raise(Ticktick::Errors::ApiError.new(status: 401, body: '{"error":"Unauthorized"}'))

    content = described_class.call.content.first
    expect(content[:text]).to include("API error", "401")
  end

  it "returns rate limit message when rate limited" do
    allow(client).to receive(:list_all_tasks)
      .and_raise(Ticktick::Errors::RateLimitError.new(status: 500, body: "exceed_query_limit"))

    response = described_class.call
    expect(response.content.first[:text]).to include("rate limit", "retry after 1 minute")
  end
end
