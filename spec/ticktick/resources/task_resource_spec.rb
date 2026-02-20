# frozen_string_literal: true

RSpec.describe Ticktick::Resources::TaskResource do
  subject(:resource) { described_class.new(connection, project_resource) }

  let(:connection) { instance_double(Ticktick::HttpConnection) }
  let(:project_resource) { instance_double(Ticktick::Resources::ProjectResource) }

  describe "#complete" do
    it "calls connection.post with project/{project_id}/task/{task_id}/complete path" do
      allow(connection).to receive(:post)
        .with("project/proj_001/task/task_001/complete")
        .and_return(nil)

      result = resource.complete("proj_001", "task_001")
      expect(result).to be_nil
      expect(connection).to have_received(:post).with("project/proj_001/task/task_001/complete")
    end
  end

  describe "#delete" do
    it "calls connection.delete with project/{project_id}/task/{task_id} path" do
      allow(connection).to receive(:delete)
        .with("project/proj_001/task/task_001")
        .and_return(nil)

      result = resource.delete("proj_001", "task_001")
      expect(result).to be_nil
      expect(connection).to have_received(:delete).with("project/proj_001/task/task_001")
    end
  end

  describe "#update" do
    it "calls connection.post_json with task/{task_id} path and request body" do
      task_attrs = instance_double(Ticktick::Resources::TaskAttributes,
                                   to_request_body: { id: "task_001", title: "Updated", projectId: "proj_001" })
      updated = { "id" => "task_001", "title" => "Updated" }
      allow(connection).to receive(:post_json)
        .with("task/task_001", { id: "task_001", title: "Updated", projectId: "proj_001" })
        .and_return(updated)

      result = resource.update("task_001", task_attrs)
      expect(result["id"]).to eq("task_001")
      expect(connection).to have_received(:post_json)
        .with("task/task_001", { id: "task_001", title: "Updated", projectId: "proj_001" })
    end
  end

  describe "#create" do
    it "calls connection.post_json with task path and request body" do
      task_attrs = instance_double(Ticktick::Resources::TaskAttributes,
                                   to_request_body: { title: "Buy milk", projectId: "proj_001" })
      created = { "id" => "task_new", "title" => "Buy milk" }
      allow(connection).to receive(:post_json).with("task", { title: "Buy milk", projectId: "proj_001" })
                                              .and_return(created)

      result = resource.create(task_attrs)
      expect(result["id"]).to eq("task_new")
      expect(connection).to have_received(:post_json).with("task", { title: "Buy milk", projectId: "proj_001" })
    end
  end

  describe "#list_all" do
    let(:projects) do
      [
        { "id" => "proj_001", "name" => "Work" },
        { "id" => "proj_002", "name" => "Personal" }
      ]
    end

    before { allow(project_resource).to receive(:list).and_return(projects) }

    it "returns all tasks across projects with project_name" do
      tasks1 = { "tasks" => [{ "id" => "t1", "title" => "Fix bug" }] }
      tasks2 = { "tasks" => [{ "id" => "t3", "title" => "Buy groceries" }] }
      allow(project_resource).to receive(:get_data).with("proj_001").and_return(tasks1)
      allow(project_resource).to receive(:get_data).with("proj_002").and_return(tasks2)

      tasks = resource.list_all
      expect(tasks.length).to eq(2)
      expect(tasks[0]).to include("project_name" => "Work", "title" => "Fix bug")
      expect(tasks[1]).to include("project_name" => "Personal", "title" => "Buy groceries")
    end

    it "skips projects whose data fetch raises ApiError" do
      error = Ticktick::Errors::ApiError.new(status: 500, body: "error")
      tasks2 = { "tasks" => [{ "id" => "t3", "title" => "Buy groceries" }] }
      allow(project_resource).to receive(:get_data).with("proj_001").and_raise(error)
      allow(project_resource).to receive(:get_data).with("proj_002").and_return(tasks2)

      tasks = resource.list_all
      expect(tasks.length).to eq(1)
      expect(tasks[0]["project_name"]).to eq("Personal")
    end

    it "handles projects with no tasks" do
      allow(project_resource).to receive(:get_data).with("proj_001").and_return({ "tasks" => [] })
      allow(project_resource).to receive(:get_data).with("proj_002").and_return({})

      expect(resource.list_all).to eq([])
    end
  end
end
