class EmailResetsController < ApplicationController
  skip_before_action :require_login, only: %i[pass update]
  def new; end

  def create
    current_user.update(reset_email: params[:reset_email])
    current_user.generate_reset_email_token!
    UserMailer.reset_email_email(current_user).deliver_later
    redirect_to profile_path, success: "メールを送信しました。"
  end

  def pass
    @user = User.find_by(reset_email_token: params[:id])

    if @user.nil?
      redirect_to profile_path, danger: "無効なリンクです。"
      return
    end
  end

  def update
    user = User.find_by(reset_email_token: params[:id])

    if user.nil? || !user.reset_email_token_valid?
      redirect_to profile_path, danger: "期限切れです。"
      return
    end

    if user.valid_password?(params[:password])
      user.update!(email: user.reset_email, reset_email: nil, reset_email_token: nil, reset_email_token_expires_at: nil)
      redirect_to profile_path, success: "メールアドレスを変更しました"
    else
      redirect_to pass_email_reset_path(id: params[:id]), danger: "パスワードが間違っています"
    end
  end
end
