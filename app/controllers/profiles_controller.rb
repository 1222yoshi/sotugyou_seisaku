class ProfilesController < ApplicationController
  before_action :set_user, only: %i[edit update show]
  before_action :combine_birthdate_params, only: [:update]

  def edit; end

  def update
    selected_areas = params[:user][:area_ids].reject(&:blank?)
    selected_instruments = params[:user][:instrument_ids].reject(&:blank?)

    if selected_areas.uniq.length != selected_areas.length
      flash[:danger] = "選択したエリアに重複があります。"
      redirect_to profile_path
    elsif selected_instruments.uniq.length != selected_instruments.length
      flash[:danger] = "選択した楽器に重複があります。"
      redirect_to profile_path
    elsif params[:user][:name].empty?
      flash[:danger] = "名前は必須項目です。"
      redirect_to profile_path
    else
      if @user.update(user_params)
        redirect_to profile_path, success: 'プロフィールを更新しました。'
      else
        flash[:danger] = "更新に失敗しました。"
        redirect_to profile_path
      end
    end
  end

  def show
    @user_albums = current_user.user_albums.includes(:album).order(order_number: :asc)
  end

  private

  def set_user
    @user = User.find(current_user.id)
  end

  def combine_birthdate_params
    if params[:user][:birth_year].present? && params[:user][:birth_month].present? && params[:user][:birth_day].present?
      birthdate = Date.new(
        params[:user][:birth_year].to_i,
        params[:user][:birth_month].to_i,
        params[:user][:birth_day].to_i
      )
      params[:user][:birthdate] = birthdate
    else
      params[:user][:birthdate] = nil
    end
  end

  def user_params
    params.require(:user).permit(:name, :birthdate, :gender, :purpose, :introduction, :profile_image, :x_link, :instagram_link, :youtube_link, :custom_link, area_ids: [], instrument_ids: [])
  end
end
