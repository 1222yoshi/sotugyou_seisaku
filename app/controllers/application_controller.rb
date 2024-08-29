class ApplicationController < ActionController::Base
  before_action :require_login
  before_action :prepare_meta_tags, if: -> { request.get? }

  add_flash_types :success, :danger
  
  private

  def not_authenticated
    redirect_to login_path
  end

  def prepare_meta_tags(options = {})
    defaults = {
      site: "MeTRO NOTE",
      title: "バンドメンバーマッチングアプリ | MeTRO NOTE",
      description: "バンドメンバーマッチングアプリ",
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        url: "https://metronote.jp",
        image: 'metro-sea.png'
      },
      twitter: {
        card: 'summary_large_image',
        image: 'metro-sea.png'
      }
    }

    options.reverse_merge!(defaults)

    set_meta_tags options
  end
end
