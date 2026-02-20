# frozen_string_literal: true

RSpec.describe Ticktick::Client do
  describe ".new" do
    it "raises AuthenticationError when token is nil" do
      expect { described_class.new(token: nil) }
        .to raise_error(Ticktick::Client::AuthenticationError, /TICKTICK_ACCESS_TOKEN/)
    end
  end

  describe "#list_projects" do
    subject(:client) { described_class.new(token: "valid_token") }

    it "returns parsed project list" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .with(headers: { "Authorization" => "Bearer valid_token" })
        .to_return(status: 200, body: [{ "id" => "proj_001", "name" => "Work" }].to_json)

      result = client.list_projects
      expect(result).to eq([{ "id" => "proj_001", "name" => "Work" }])
    end

    it "raises ApiError on HTTP error" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 401, body: '{"error":"Unauthorized"}')

      expect { client.list_projects }
        .to raise_error(Ticktick::Client::ApiError) { |e|
          expect(e.status).to eq(401)
          expect(e.body).to include("Unauthorized")
        }
    end
  end

  describe "#get_project" do
    subject(:client) { described_class.new(token: "valid_token") }

    it "returns parsed project data" do
      body = { "id" => "proj_001", "name" => "Work", "color" => "#F18181", "closed" => false }
      stub_request(:get, "https://api.ticktick.com/open/v1/project/proj_001")
        .with(headers: { "Authorization" => "Bearer valid_token" })
        .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })

      result = client.get_project("proj_001")
      expect(result["name"]).to eq("Work")
    end

    it "raises ApiError on HTTP 404" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project/not_exist")
        .to_return(status: 404, body: '{"error":"Not Found"}')

      expect { client.get_project("not_exist") }
        .to raise_error(Ticktick::Client::ApiError) { |e| expect(e.status).to eq(404) }
    end
  end

  describe "#get_project_data" do
    subject(:client) { described_class.new(token: "valid_token") }

    it "returns parsed project data" do
      body = {
        "project" => { "id" => "proj_001", "name" => "Work" },
        "tasks" => [{ "id" => "task_001", "title" => "Buy groceries" }],
        "columns" => [{ "id" => "col_001", "name" => "To Do" }]
      }
      stub_request(:get, "https://api.ticktick.com/open/v1/project/proj_001/data")
        .with(headers: { "Authorization" => "Bearer valid_token" })
        .to_return(status: 200, body: body.to_json)

      result = client.get_project_data("proj_001")
      expect(result["project"]["name"]).to eq("Work")
      expect(result["tasks"].first["title"]).to eq("Buy groceries")
    end

    it "raises ApiError on HTTP error" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project/proj_001/data")
        .to_return(status: 404, body: '{"error":"Not found"}')

      expect { client.get_project_data("proj_001") }
        .to raise_error(Ticktick::Client::ApiError) { |e|
          expect(e.status).to eq(404)
        }
    end
  end

  describe "#create_project" do
    subject(:client) { described_class.new(token: "valid_token") }

    it "creates a project with name only and returns parsed response" do
      created = { "id" => "proj_new", "name" => "New Project" }
      stub_request(:post, "https://api.ticktick.com/open/v1/project")
        .with(
          headers: { "Authorization" => "Bearer valid_token", "Content-Type" => "application/json" },
          body: { name: "New Project" }.to_json
        )
        .to_return(status: 200, body: created.to_json)

      result = client.create_project(name: "New Project")
      expect(result["id"]).to eq("proj_new")
      expect(result["name"]).to eq("New Project")
    end

    it "creates a project with all optional parameters" do
      body = { name: "Work", color: "#F18181", sortOrder: 1, viewMode: "kanban", kind: "TASK" }.to_json
      created = { "id" => "proj_001", "name" => "Work", "color" => "#F18181" }
      stub_request(:post, "https://api.ticktick.com/open/v1/project")
        .with(body: body)
        .to_return(status: 200, body: created.to_json)

      result = client.create_project(name: "Work", color: "#F18181", sort_order: 1, view_mode: "kanban", kind: "TASK")
      expect(result["color"]).to eq("#F18181")
    end

    it "raises ApiError on HTTP error" do
      stub_request(:post, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 400, body: '{"error":"Bad Request"}')

      expect { client.create_project(name: "Bad") }
        .to raise_error(Ticktick::Client::ApiError) { |e| expect(e.status).to eq(400) }
    end

    it "raises RateLimitError when rate limited" do
      rate_limit_body = { "errorCode" => "exceed_query_limit" }.to_json
      stub_request(:post, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 500, body: rate_limit_body)

      expect { client.create_project(name: "Test") }
        .to raise_error(Ticktick::Client::RateLimitError)
    end
  end

  describe "#update_project" do
    subject(:client) { described_class.new(token: "valid_token") }

    it "updates a project and returns parsed response" do
      updated = { "id" => "proj_001", "name" => "Renamed" }
      stub_request(:post, "https://api.ticktick.com/open/v1/project/proj_001")
        .with(
          headers: { "Authorization" => "Bearer valid_token", "Content-Type" => "application/json" },
          body: { name: "Renamed" }.to_json
        )
        .to_return(status: 200, body: updated.to_json)

      result = client.update_project("proj_001", name: "Renamed")
      expect(result["id"]).to eq("proj_001")
      expect(result["name"]).to eq("Renamed")
    end

    it "sends only specified optional fields in request body" do
      updated = { "id" => "proj_001", "color" => "#F18181", "viewMode" => "kanban" }
      stub_request(:post, "https://api.ticktick.com/open/v1/project/proj_001")
        .with(body: { color: "#F18181", viewMode: "kanban" }.to_json)
        .to_return(status: 200, body: updated.to_json)

      result = client.update_project("proj_001", color: "#F18181", view_mode: "kanban")
      expect(result["color"]).to eq("#F18181")
    end

    it "raises ApiError on HTTP error" do
      stub_request(:post, "https://api.ticktick.com/open/v1/project/proj_001")
        .to_return(status: 401, body: '{"error":"Unauthorized"}')

      expect { client.update_project("proj_001", name: "Test") }
        .to raise_error(Ticktick::Client::ApiError) { |e| expect(e.status).to eq(401) }
    end

    it "raises RateLimitError when rate limited" do
      rate_limit_body = { "errorCode" => "exceed_query_limit" }.to_json
      stub_request(:post, "https://api.ticktick.com/open/v1/project/proj_001")
        .to_return(status: 500, body: rate_limit_body)

      expect { client.update_project("proj_001", name: "Test") }
        .to raise_error(Ticktick::Client::RateLimitError)
    end
  end

  describe "#create_task" do
    subject(:client) { described_class.new(token: "valid_token") }

    it "creates a task with title and project_id only" do
      created = { "id" => "task_new", "title" => "Buy milk", "projectId" => "proj_001" }
      stub_request(:post, "https://api.ticktick.com/open/v1/task")
        .with(
          headers: { "Authorization" => "Bearer valid_token", "Content-Type" => "application/json" },
          body: { title: "Buy milk", projectId: "proj_001" }.to_json
        )
        .to_return(status: 200, body: created.to_json)

      result = client.create_task(title: "Buy milk", project_id: "proj_001")
      expect(result["id"]).to eq("task_new")
      expect(result["title"]).to eq("Buy milk")
    end

    it "creates a task with all optional parameters and converts to camelCase" do
      expected_body = {
        title: "Meeting",
        projectId: "proj_001",
        content: "Agenda",
        desc: "Notes",
        isAllDay: false,
        startDate: "2026-02-20T09:00:00+0000",
        dueDate: "2026-02-20T10:00:00+0000",
        timeZone: "America/Los_Angeles",
        reminders: ["TRIGGER:P0DT9H0M0S"],
        repeatFlag: "RRULE:FREQ=DAILY;INTERVAL=1",
        priority: 3,
        sortOrder: 0,
        items: [{ "title" => "Subtask 1" }]
      }.to_json
      created = { "id" => "task_new", "title" => "Meeting" }
      stub_request(:post, "https://api.ticktick.com/open/v1/task")
        .with(body: expected_body)
        .to_return(status: 200, body: created.to_json)

      result = client.create_task(
        title: "Meeting",
        project_id: "proj_001",
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
      expect(result["title"]).to eq("Meeting")
    end

    it "raises RateLimitError when rate limited" do
      rate_limit_body = { "errorCode" => "exceed_query_limit" }.to_json
      stub_request(:post, "https://api.ticktick.com/open/v1/task")
        .to_return(status: 500, body: rate_limit_body)

      expect { client.create_task(title: "Test", project_id: "proj_001") }
        .to raise_error(Ticktick::Client::RateLimitError)
    end

    it "raises ApiError on HTTP error" do
      stub_request(:post, "https://api.ticktick.com/open/v1/task")
        .to_return(status: 401, body: '{"error":"Unauthorized"}')

      expect { client.create_task(title: "Test", project_id: "proj_001") }
        .to raise_error(Ticktick::Client::ApiError) { |e| expect(e.status).to eq(401) }
    end
  end

  describe "rate limit detection" do
    subject(:client) { described_class.new(token: "valid_token") }

    let(:rate_limit_body) do
      {
        "errorId" => "test@server-01",
        "errorCode" => "exceed_query_limit",
        "errorMessage" => "Query rate limit exceeded. Maximum 100 requests per minute. Please retry later.",
        "data" => nil
      }.to_json
    end

    it "raises RateLimitError when API returns exceed_query_limit" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 500, body: rate_limit_body)

      expect { client.list_projects }
        .to raise_error(Ticktick::Client::RateLimitError) { |e|
          expect(e.status).to eq(500)
          expect(e.body).to include("exceed_query_limit")
        }
    end

    it "raises RateLimitError on get_project_data" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project/proj_001/data")
        .to_return(status: 500, body: rate_limit_body)

      expect { client.get_project_data("proj_001") }
        .to raise_error(Ticktick::Client::RateLimitError)
    end

    it "raises plain ApiError for non-rate-limit 500 errors" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 500, body: '{"errorCode":"internal_error"}')

      expect { client.list_projects }
        .to raise_error(Ticktick::Client::ApiError) { |e|
          expect(e).not_to be_a(Ticktick::Client::RateLimitError)
        }
    end

    it "raises plain ApiError for non-JSON error responses" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 500, body: "Internal Server Error")

      expect { client.list_projects }
        .to raise_error(Ticktick::Client::ApiError) { |e|
          expect(e).not_to be_a(Ticktick::Client::RateLimitError)
        }
    end
  end

  describe "#list_all_tasks" do
    subject(:client) { described_class.new(token: "valid_token") }

    before do
      stub_request(:get, "https://api.ticktick.com/open/v1/project")
        .to_return(status: 200, body: [
          { "id" => "proj_001", "name" => "Work" },
          { "id" => "proj_002", "name" => "Personal" }
        ].to_json)
    end

    it "returns all tasks across projects with project_name" do
      stub_project_data("proj_001", [{ "id" => "t1", "title" => "Fix bug" }])
      stub_project_data("proj_002", [{ "id" => "t3", "title" => "Buy groceries" }])

      tasks = client.list_all_tasks
      expect(tasks.length).to eq(2)
      expect(tasks[0]).to include("project_name" => "Work", "title" => "Fix bug")
      expect(tasks[1]).to include("project_name" => "Personal", "title" => "Buy groceries")
    end

    it "skips projects whose data fetch fails" do
      stub_request(:get, "https://api.ticktick.com/open/v1/project/proj_001/data")
        .to_return(status: 500, body: "Internal Server Error")
      stub_project_data("proj_002", [{ "id" => "t3", "title" => "Buy groceries" }])

      tasks = client.list_all_tasks
      expect(tasks.length).to eq(1)
      expect(tasks[0]["project_name"]).to eq("Personal")
    end

    def stub_project_data(project_id, tasks)
      body = { "tasks" => tasks }.to_json
      stub_request(:get, "https://api.ticktick.com/open/v1/project/#{project_id}/data")
        .to_return(status: 200, body: body)
    end
  end
end
