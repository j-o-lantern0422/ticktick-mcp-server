# frozen_string_literal: true

RSpec.describe Ticktick::Mcp::Server::DeleteTask do
  let(:client) { instance_double(Ticktick::Client) }

  before { allow(Ticktick::Client).to receive(:new).and_return(client) }

  it "returns success message when task is deleted" do
    allow(client).to receive(:delete_task).with(project_id: "proj_001", task_id: "task_001").and_return(nil)

    response = described_class.call(project_id: "proj_001", task_id: "task_001")
    expect(response.content.first[:text]).to eq("Task task_001 deleted.")
  end

  it "returns error when token is missing" do
    allow(Ticktick::Client).to receive(:new)
      .and_raise(Ticktick::Errors::AuthenticationError, "Environment variable TICKTICK_ACCESS_TOKEN is not set")

    response = described_class.call(project_id: "proj_001", task_id: "task_001")
    expect(response.content.first[:text]).to include("TICKTICK_ACCESS_TOKEN")
  end

  it "returns error on API failure" do
    allow(client).to receive(:delete_task)
      .and_raise(Ticktick::Errors::ApiError.new(status: 404, body: '{"error":"Not Found"}'))

    response = described_class.call(project_id: "proj_001", task_id: "task_001")
    expect(response.content.first[:text]).to include("API error", "404")
  end

  it "returns rate limit message when rate limited" do
    allow(client).to receive(:delete_task)
      .and_raise(Ticktick::Errors::RateLimitError.new(status: 500, body: "exceed_query_limit"))

    response = described_class.call(project_id: "proj_001", task_id: "task_001")
    expect(response.content.first[:text]).to include("rate limit", "retry after 1 minute")
  end
end
