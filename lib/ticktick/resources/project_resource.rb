# frozen_string_literal: true

module Ticktick
  module Resources
    class ProjectResource
      def initialize(connection)
        @connection = connection
      end

      def list
        @connection.get("project")
      end

      def get(project_id)
        @connection.get("project/#{project_id}")
      end

      def get_data(project_id)
        @connection.get("project/#{project_id}/data")
      end

      def create(name:, color: nil, sort_order: nil, view_mode: nil, kind: nil)
        body = { name: name }
        body[:color] = color if color
        body[:sortOrder] = sort_order if sort_order
        body[:viewMode] = view_mode if view_mode
        body[:kind] = kind if kind
        @connection.post_json("project", body)
      end

      def update(project_id, name: nil, color: nil, sort_order: nil, view_mode: nil, kind: nil)
        body = { name: name, color: color, sortOrder: sort_order, viewMode: view_mode, kind: kind }.compact
        @connection.post_json("project/#{project_id}", body)
      end

      def delete(project_id)
        @connection.delete("project/#{project_id}")
      end
    end
  end
end
