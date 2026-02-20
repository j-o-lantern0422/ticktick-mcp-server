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
