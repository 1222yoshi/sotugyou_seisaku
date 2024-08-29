class ApplicationController < ActionController::Base
  before_action :require_login

  add_flash_types :success, :danger
  
  private

  def not_authenticated
    redirect_to login_path
  end

  def prepare_meta_tags(options = {})
    defaults = {
      site:        "MeTRO NOTE",
      description: "バンドメンバーマッチングアプリ",
      og: {
        site_name: :site,
        description: :description,
        url: "https://metronote.jp",
        image: image_url('metro-sea.png')
      },
      twitter: {
        card: 'summary_large_image',
        image: image_url('metro-sea.png')
      }
    }

    options.reverse_merge!(defaults)

    set_meta_tags options
  end
end
