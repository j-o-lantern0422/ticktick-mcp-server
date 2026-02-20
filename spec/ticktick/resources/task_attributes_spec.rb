# frozen_string_literal: true

RSpec.describe Ticktick::Resources::TaskAttributes do
  describe "#to_request_body" do
    it "returns minimal body with only title and project_id" do
      attrs = described_class.new(title: "Buy milk", project_id: "proj_001")
      expect(attrs.to_request_body).to eq({ title: "Buy milk", projectId: "proj_001" })
    end

    it "converts snake_case keys to camelCase" do
      attrs = described_class.new(
        title: "Meeting",
        project_id: "proj_001",
        is_all_day: false,
        start_date: "2026-02-20T09:00:00+0000",
        due_date: "2026-02-20T10:00:00+0000",
        time_zone: "America/Los_Angeles",
        repeat_flag: "RRULE:FREQ=DAILY;INTERVAL=1",
        sort_order: 0
      )
      body = attrs.to_request_body
      expect(body[:isAllDay]).to eq(false)
      expect(body[:startDate]).to eq("2026-02-20T09:00:00+0000")
      expect(body[:dueDate]).to eq("2026-02-20T10:00:00+0000")
      expect(body[:timeZone]).to eq("America/Los_Angeles")
      expect(body[:repeatFlag]).to eq("RRULE:FREQ=DAILY;INTERVAL=1")
      expect(body[:sortOrder]).to eq(0)
      expect(body[:projectId]).to eq("proj_001")
    end

    it "omits nil values from the body" do
      attrs = described_class.new(title: "Task", project_id: "proj_001", content: nil, desc: nil)
      body = attrs.to_request_body
      expect(body).not_to have_key(:content)
      expect(body).not_to have_key(:desc)
    end

    it "includes all provided optional fields" do
      attrs = described_class.new(
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
      body = attrs.to_request_body
      expect(body).to eq(
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
      )
    end

    it "keeps false values (does not treat false as nil)" do
      attrs = described_class.new(title: "Task", project_id: "proj_001", is_all_day: false)
      expect(attrs.to_request_body[:isAllDay]).to eq(false)
    end

    it "keeps zero as sort_order (does not treat 0 as nil)" do
      attrs = described_class.new(title: "Task", project_id: "proj_001", sort_order: 0)
      expect(attrs.to_request_body[:sortOrder]).to eq(0)
    end

    it "includes id in the body when provided" do
      attrs = described_class.new(title: "Task", project_id: "proj_001", id: "task_001")
      expect(attrs.to_request_body[:id]).to eq("task_001")
    end

    it "omits id from the body when not provided (create_task compatibility)" do
      attrs = described_class.new(title: "Task", project_id: "proj_001")
      expect(attrs.to_request_body).not_to have_key(:id)
    end
  end
end
