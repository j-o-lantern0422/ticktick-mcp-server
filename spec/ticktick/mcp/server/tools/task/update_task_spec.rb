# frozen_string_literal: true

RSpec.describe Ticktick::Mcp::Server::UpdateTask do
  let(:client) { instance_double(Ticktick::Client) }

  before { allow(Ticktick::Client).to receive(:new).and_return(client) }

  it "returns updated task as formatted JSON" do
    task = { "id" => "task_001", "title" => "Updated title", "projectId" => "proj_001" }
    allow(client).to receive(:update_task)
      .with(task_id: "task_001", project_id: "proj_001", title: nil, content: nil, desc: nil,
            is_all_day: nil, start_date: nil, due_date: nil, time_zone: nil,
            reminders: nil, repeat_flag: nil, priority: nil, sort_order: nil, items: nil)
      .and_return(task)

    parsed = JSON.parse(described_class.call(task_id: "task_001", project_id: "proj_001").content.first[:text])
    expect(parsed["id"]).to eq("task_001")
    expect(parsed["projectId"]).to eq("proj_001")
  end

  it "passes all optional parameters to the client" do
    task = { "id" => "task_001", "title" => "Meeting" }
    allow(client).to receive(:update_task)
      .with(
        task_id: "task_001",
        project_id: "proj_001",
        title: "Meeting",
        content: "Agenda",
        desc: "Notes",
        is_all_day: false,
        start_date: "2026-02-20T09:00:00+0000",
        due_date: "2026-02-20T10:00:00+0000",
        time_zone: "America/Los_Angeles",
        reminders: ["TRIGGER:P0DT9H0M0S"],
        repeat_flag: "RRULE:FREQ=DAILY;INTERVAL=1",
        priority: 3,
        sort_order: 0,
        items: [{ "title" => "Subtask 1" }]
      )
      .and_return(task)

    response = described_class.call(
      task_id: "task_001",
      project_id: "proj_001",
      title: "Meeting",
      content: "Agenda",
      desc: "Notes",
      is_all_day: false,
      start_date: "2026-02-20T09:00:00+0000",
      due_date: "2026-02-20T10:00:00+0000",
      time_zone: "America/Los_Angeles",
      reminders: ["TRIGGER:P0DT9H0M0S"],
      repeat_flag: "RRULE:FREQ=DAILY;INTERVAL=1",
      priority: 3,
      sort_order: 0,
      items: [{ "title" => "Subtask 1" }]
    )
    parsed = JSON.parse(response.content.first[:text])
    expect(parsed["title"]).to eq("Meeting")
  end

  it "returns error when token is missing" do
    allow(Ticktick::Client).to receive(:new)
      .and_raise(Ticktick::Errors::AuthenticationError, "Environment variable TICKTICK_ACCESS_TOKEN is not set")

    response = described_class.call(task_id: "task_001", project_id: "proj_001")
    expect(response.content.first[:text]).to include("TICKTICK_ACCESS_TOKEN")
  end

  it "returns error on API failure" do
    allow(client).to receive(:update_task)
      .and_raise(Ticktick::Errors::ApiError.new(status: 400, body: '{"error":"Bad Request"}'))

    content = described_class.call(task_id: "task_001", project_id: "proj_001").content.first
    expect(content[:text]).to include("API error", "400")
  end

  it "returns rate limit message when rate limited" do
    allow(client).to receive(:update_task)
      .and_raise(Ticktick::Errors::RateLimitError.new(status: 500, body: "exceed_query_limit"))

    response = described_class.call(task_id: "task_001", project_id: "proj_001")
    expect(response.content.first[:text]).to include("rate limit", "retry after 1 minute")
  end
end
