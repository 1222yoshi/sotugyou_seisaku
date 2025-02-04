class ApplicationController < ActionController::Base
  before_action :require_login
  before_action :prepare_meta_tags, if: -> { request.get? }
  before_action :header_color

  add_flash_types :success, :danger

  private

  def not_authenticated
    redirect_to login_path
  end

  def prepare_meta_tags(options = {})
    defaults = {
      site: 'MeTRO NOTE',
      title: 'MeTRO NOTE',
      description: 'AIを使ったバンドメンバーマッチングアプリ',
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        url: 'https://metronote.jp',
        image: 'https://metronote.jp/assets/metro-logo.png'
      },
      twitter: {
        card: 'summary_large_image',
        image: 'https://metronote.jp/assets/metro-logo.png'
      }
    }

    options.reverse_merge!(defaults)

    set_meta_tags options
  end

  def header_color
    @likes_color = likes_user_icon
    @chatroom_color = chatroom_icon
  end

  def likes_user_icon
    return unless current_user

    unread_notifications = Notification.where(is_read: false, user_id: current_user.id, notification_type: 'like')
    return 'neon-text-off' if unread_notifications.empty?

    source_user_ids = unread_notifications.map(&:source_user_id).uniq

    source_user_ids.each do |source_user_id|
      return 's-neon' if Like.exists?(like_user_id: current_user.id, liked_user_id: source_user_id)
    end
    'neon-logo-on'
  end

  def chatroom_icon
    return unless current_user

    if Notification.exists?(is_read: false, user_id: current_user.id, notification_type: 'message')
      'neon-logo-on'
    else
      'neon-text-off'
    end
  end
end
