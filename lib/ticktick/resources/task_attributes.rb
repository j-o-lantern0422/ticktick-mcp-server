# frozen_string_literal: true

module Ticktick
  module Resources
    class TaskAttributes
      # rubocop:disable Metrics/MethodLength
      def initialize(title:, project_id:, content: nil, desc: nil,
                     is_all_day: nil, start_date: nil, due_date: nil,
                     time_zone: nil, reminders: nil, repeat_flag: nil,
                     priority: nil, sort_order: nil, items: nil)
        @title = title
        @project_id = project_id
        @content = content
        @desc = desc
        @is_all_day = is_all_day
        @start_date = start_date
        @due_date = due_date
        @time_zone = time_zone
        @reminders = reminders
        @repeat_flag = repeat_flag
        @priority = priority
        @sort_order = sort_order
        @items = items
      end
      # rubocop:enable Metrics/MethodLength

      def to_request_body
        {
          title: @title, projectId: @project_id, content: @content,
          desc: @desc, isAllDay: @is_all_day, startDate: @start_date,
          dueDate: @due_date, timeZone: @time_zone, reminders: @reminders,
          repeatFlag: @repeat_flag, priority: @priority,
          sortOrder: @sort_order, items: @items
        }.compact
      end
    end
  end
end
