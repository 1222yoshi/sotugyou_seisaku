class OtherUsersController < ApplicationController
  skip_before_action :require_login, only: %i[index show]

  def index; end

  def show
    @user = User.find(params[:id])
    set_meta_tags   twitter: {
                    title: "＃私を構成する９枚",
                    card: "summary_large_image",
                    url: "https://metronote-a37794a02853.herokuapp.com/other_users/#{@user.id}?#{current_time}",
                    image:  "https://metronote-a37794a02853.herokuapp.com/album_grid_#{@user.id}.png"
                  }
    @user_albums = @user.user_albums.includes(:album).order(created_at: :asc)
  end
end
