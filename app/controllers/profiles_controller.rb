class ProfilesController < ApplicationController
  before_action :set_user, only: %i[edit update]

  def edit; end

  def update
    if @user.update(user_params)
      redirect_to profile_path, success: 'プロフィールを更新しました。'
    else
      flash[:danger]
    end
  end

  def show; end

  private

  def set_user
    @user = User.find(current_user.id)
  end

  def user_params
    params.require(:user).premit(:name, :birthdate, :gender, :introduction, :profile_image, :profile_image_cache, :x_link, :instagram_link, :youtube_link, :custom_link)
  end
end
