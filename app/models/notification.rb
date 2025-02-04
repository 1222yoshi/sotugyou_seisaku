class Notification < ApplicationRecord
  belongs_to :user, class_name: 'User'
  belongs_to :source_user, class_name: 'User'

  after_create_commit :check_notifications

  def check_notifications
    like_notifications = Notification.where(is_read: false, notification_type: 'like').group_by(&:user_id)
    like_notifications.each do |user_id, notifications|
      source_user_ids = notifications.map(&:source_user_id).uniq
      flag = 0
      source_user_ids.each do |source_user_id|
        next unless Like.exists?(like_user_id: user_id, liked_user_id: source_user_id)

        ActionCable.server.broadcast "notifications_#{user_id}", { action: 'match' }
        flag = 1
        break
      end
      ActionCable.server.broadcast "notifications_#{user_id}", { action: 'new' } if flag == 0
    end

    message_notifications = Notification.where(is_read: false, notification_type: 'message').group_by(&:user_id)

    message_notifications.each do |user_id, _notifications|
      ActionCable.server.broadcast "notifications_#{user_id}", { action: 'message' }
    end
  end
end
