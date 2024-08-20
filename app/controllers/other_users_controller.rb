class OtherUsersController < ApplicationController
  skip_before_action :require_login, only: %i[index show]

  def index; end

  def show
    @user = User.find(params[:id])
    @user_albums = @user.user_albums.includes(:album).order(created_at: :asc)
  end

end
