# frozen_string_literal: true

RSpec.describe Ticktick::Resources::ProjectResource do
  subject(:resource) { described_class.new(connection) }

  let(:connection) { instance_double(Ticktick::HttpConnection) }

  describe "#list" do
    it "calls connection.get with 'project'" do
      allow(connection).to receive(:get).with("project").and_return([])
      expect(resource.list).to eq([])
      expect(connection).to have_received(:get).with("project")
    end
  end

  describe "#get" do
    it "calls connection.get with project path" do
      allow(connection).to receive(:get).with("project/proj_001").and_return({ "id" => "proj_001" })
      result = resource.get("proj_001")
      expect(result["id"]).to eq("proj_001")
      expect(connection).to have_received(:get).with("project/proj_001")
    end
  end

  describe "#get_data" do
    it "calls connection.get with project data path" do
      data = { "project" => {}, "tasks" => [] }
      allow(connection).to receive(:get).with("project/proj_001/data").and_return(data)
      result = resource.get_data("proj_001")
      expect(result["tasks"]).to eq([])
      expect(connection).to have_received(:get).with("project/proj_001/data")
    end
  end

  describe "#create" do
    it "calls connection.post_json with 'project' and body containing name" do
      created = { "id" => "proj_new", "name" => "New Project" }
      allow(connection).to receive(:post_json).with("project", { name: "New Project" }).and_return(created)
      result = resource.create(name: "New Project")
      expect(result["id"]).to eq("proj_new")
    end

    it "includes optional fields in request body" do
      expected_body = { name: "Work", color: "#F18181", sortOrder: 1, viewMode: "kanban", kind: "TASK" }
      allow(connection).to receive(:post_json).with("project", expected_body).and_return({})
      resource.create(name: "Work", color: "#F18181", sort_order: 1, view_mode: "kanban", kind: "TASK")
      expect(connection).to have_received(:post_json).with("project", expected_body)
    end

    it "omits nil optional fields from request body" do
      allow(connection).to receive(:post_json).with("project", { name: "Minimal" }).and_return({})
      resource.create(name: "Minimal")
      expect(connection).to have_received(:post_json).with("project", { name: "Minimal" })
    end
  end

  describe "#update" do
    it "calls connection.post_json with project path and body" do
      updated = { "id" => "proj_001", "name" => "Renamed" }
      allow(connection).to receive(:post_json).with("project/proj_001", { name: "Renamed" }).and_return(updated)
      result = resource.update("proj_001", name: "Renamed")
      expect(result["name"]).to eq("Renamed")
    end

    it "sends only specified optional fields" do
      expected_body = { color: "#F18181", viewMode: "kanban" }
      allow(connection).to receive(:post_json).with("project/proj_001", expected_body).and_return({})
      resource.update("proj_001", color: "#F18181", view_mode: "kanban")
      expect(connection).to have_received(:post_json).with("project/proj_001", expected_body)
    end
  end

  describe "#delete" do
    it "calls connection.delete with project path" do
      allow(connection).to receive(:delete).with("project/proj_001").and_return(nil)
      result = resource.delete("proj_001")
      expect(result).to be_nil
      expect(connection).to have_received(:delete).with("project/proj_001")
    end
  end
end
