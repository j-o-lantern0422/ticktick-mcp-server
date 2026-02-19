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

  describe Ticktick::Mcp::Server::ListProjects do
    let(:project_response_body) do
      [
        { "id" => "proj_001", "name" => "Work", "sortOrder" => 0 },
        { "id" => "proj_002", "name" => "Personal", "sortOrder" => 1 }
      ].to_json
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

      it "returns project list" do
        stub_request(:get, "https://api.ticktick.com/open/v1/project")
          .with(headers: { "Authorization" => "Bearer valid_token" })
          .to_return(status: 200, body: project_response_body, headers: { "Content-Type" => "application/json" })

        response = described_class.call
        expect(response).to be_a(MCP::Tool::Response)
        content = response.content.first
        expect(content[:type]).to eq("text")

        parsed = JSON.parse(content[:text])
        expect(parsed.length).to eq(2)
        expect(parsed.first["name"]).to eq("Work")
      end
    end

    context "when authentication fails" do
      before { ENV["TICKTICK_ACCESS_TOKEN"] = "invalid_token" }
      after { ENV.delete("TICKTICK_ACCESS_TOKEN") }

      it "returns an error response" do
        stub_request(:get, "https://api.ticktick.com/open/v1/project")
          .with(headers: { "Authorization" => "Bearer invalid_token" })
          .to_return(status: 401, body: '{"error":"Unauthorized"}')

        response = described_class.call
        content = response.content.first
        expect(content[:text]).to include("Authentication failed")
        expect(content[:text]).to include("401")
      end
    end
  end

  describe Ticktick::Mcp::Server::GetProjectData do
    let(:project_data_response_body) do
      {
        "project" => { "id" => "proj_001", "name" => "Work", "color" => "#4772FA", "closed" => false,
                       "groupId" => nil, "viewMode" => "list", "kind" => "TASK" },
        "tasks" => [
          { "id" => "task_001", "projectId" => "proj_001", "title" => "Buy groceries",
            "isAllDay" => false, "priority" => 0, "status" => 0, "sortOrder" => 0, "items" => [] }
        ],
        "columns" => [
          { "id" => "col_001", "projectId" => "proj_001", "name" => "To Do", "sortOrder" => 0 }
        ]
      }.to_json
    end

    context "when TICKTICK_ACCESS_TOKEN is not set" do
      before { ENV.delete("TICKTICK_ACCESS_TOKEN") }

      it "returns an error response" do
        response = described_class.call(project_id: "proj_001")
        expect(response).to be_a(MCP::Tool::Response)
        content = response.content.first
        expect(content[:type]).to eq("text")
        expect(content[:text]).to include("TICKTICK_ACCESS_TOKEN")
      end
    end

    context "when authentication succeeds" do
      before { ENV["TICKTICK_ACCESS_TOKEN"] = "valid_token" }
      after { ENV.delete("TICKTICK_ACCESS_TOKEN") }

      it "returns project data with tasks and columns" do
        stub_request(:get, "https://api.ticktick.com/open/v1/project/proj_001/data")
          .with(headers: { "Authorization" => "Bearer valid_token" })
          .to_return(status: 200, body: project_data_response_body, headers: { "Content-Type" => "application/json" })

        response = described_class.call(project_id: "proj_001")
        expect(response).to be_a(MCP::Tool::Response)
        content = response.content.first
        expect(content[:type]).to eq("text")

        parsed = JSON.parse(content[:text])
        expect(parsed["project"]["name"]).to eq("Work")
        expect(parsed["tasks"].length).to eq(1)
        expect(parsed["tasks"].first["title"]).to eq("Buy groceries")
        expect(parsed["columns"].length).to eq(1)
        expect(parsed["columns"].first["name"]).to eq("To Do")
      end
    end

    context "when authentication fails" do
      before { ENV["TICKTICK_ACCESS_TOKEN"] = "invalid_token" }
      after { ENV.delete("TICKTICK_ACCESS_TOKEN") }

      it "returns an error response" do
        stub_request(:get, "https://api.ticktick.com/open/v1/project/proj_001/data")
          .with(headers: { "Authorization" => "Bearer invalid_token" })
          .to_return(status: 401, body: '{"error":"Unauthorized"}')

        response = described_class.call(project_id: "proj_001")
        content = response.content.first
        expect(content[:text]).to include("Authentication failed")
        expect(content[:text]).to include("401")
      end
    end
  end
end
