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
      description: "完全実力主義のバンドメンバーマッチングアプリ",
      og: {
        site_name: "MeTRO NOTE",
        description: "完全実力主義のバンドメンバーマッチングアプリ",
        url: "https://metronote-a37794a02853.herokuapp.com"
      },
      twitter: {
        card: "summary_large_image"
      }
    }

    options.reverse_merge!(defaults)

    set_meta_tags options
  end
end
