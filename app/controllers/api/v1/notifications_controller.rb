# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < BaseController
      def index
        page = [params.fetch(:page, 1).to_i, 1].max
        per_page = [params.fetch(:per_page, 25).to_i, 25].min

        scope = current_user.notifications.recent
        scope = scope.where(read: false) if ActiveModel::Type::Boolean.new.cast(params[:unread_only])
        total = scope.count
        records = scope.offset((page - 1) * per_page).limit(per_page)
        total_pages = [(total.to_f / per_page).ceil, 1].max

        render json: {
          data: records.map { |row| serialize(row) },
          meta: {
            total: total,
            page: page,
            per_page: per_page,
            total_pages: total_pages,
            unread_count: current_user.notifications.where(read: false).count
          }
        }, status: :ok
      end

      def read
        row = current_user.notifications.find(params[:id])
        row.update!(read: true, read_at: Time.current)
        render json: { data: { updated: true, unread_count: current_user.notifications.where(read: false).count } }, status: :ok
      end

      def read_all
        current_user.notifications.where(read: false).update_all(read: true, read_at: Time.current)
        render json: { data: { updated: true, unread_count: 0 } }, status: :ok
      end

      private

      def serialize(row)
        {
          id: row.id,
          type: row.notification_type,
          title: row.title,
          body: row.body,
          read: row.read,
          created_at: row.created_at.iso8601,
          related_resource_type: row.related_resource_type,
          related_resource_id: row.related_resource_id,
          deep_link: row.deep_link,
          metadata: row.metadata
        }
      end
    end
  end
end
