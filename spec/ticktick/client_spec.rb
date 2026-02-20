# frozen_string_literal: true

RSpec.describe Ticktick::Client do
  subject(:client) { described_class.new(token: "valid_token") }

  let(:projects) { instance_double(Ticktick::Resources::ProjectResource) }
  let(:tasks)    { instance_double(Ticktick::Resources::TaskResource) }

  before do
    allow(Ticktick::Resources::ProjectResource).to receive(:new).and_return(projects)
    allow(Ticktick::Resources::TaskResource).to receive(:new).and_return(tasks)
  end

  describe "#list_projects" do
    it "delegates to ProjectResource#list" do
      allow(projects).to receive(:list).and_return([])
      expect(client.list_projects).to eq([])
      expect(projects).to have_received(:list)
    end
  end

  describe "#get_project" do
    it "delegates to ProjectResource#get" do
      allow(projects).to receive(:get).with("proj_001").and_return({ "id" => "proj_001" })
      expect(client.get_project("proj_001")).to eq({ "id" => "proj_001" })
    end
  end

  describe "#get_project_data" do
    it "delegates to ProjectResource#get_data" do
      allow(projects).to receive(:get_data).with("proj_001").and_return({ "tasks" => [] })
      expect(client.get_project_data("proj_001")).to eq({ "tasks" => [] })
    end
  end

  describe "#create_project" do
    it "delegates to ProjectResource#create" do
      allow(projects).to receive(:create).with(name: "New Project").and_return({ "id" => "proj_new" })
      expect(client.create_project(name: "New Project")).to eq({ "id" => "proj_new" })
    end
  end

  describe "#update_project" do
    it "delegates to ProjectResource#update" do
      allow(projects).to receive(:update).with("proj_001", name: "Renamed").and_return({ "id" => "proj_001" })
      expect(client.update_project("proj_001", name: "Renamed")).to eq({ "id" => "proj_001" })
    end
  end

  describe "#list_all_tasks" do
    it "delegates to TaskResource#list_all" do
      allow(tasks).to receive(:list_all).and_return([{ "title" => "Task 1" }])
      expect(client.list_all_tasks).to eq([{ "title" => "Task 1" }])
    end
  end

  describe "#create_task" do
    it "delegates to TaskResource#create with a TaskAttributes instance" do
      created = { "id" => "task_new", "title" => "Buy milk" }
      allow(tasks).to receive(:create).and_return(created)

      result = client.create_task(title: "Buy milk", project_id: "proj_001")
      expect(result).to eq(created)
      expect(tasks).to have_received(:create) do |attrs|
        expect(attrs).to be_a(Ticktick::Resources::TaskAttributes)
        body = attrs.to_request_body
        expect(body[:title]).to eq("Buy milk")
        expect(body[:projectId]).to eq("proj_001")
      end
    end
  end
end
