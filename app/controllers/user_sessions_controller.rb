class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new; end

  def create
    @user = login(params[:email], params[:password])

    if @user
      cookies.signed[:user_id] = @user.id
      redirect_to root_path, success: 'ログインしました'
    else
      flash[:danger] = 'ログインに失敗しました'
      redirect_to login_path
    end
  end

  def destroy
    cookies.signed[:user_id] = nil
    logout
    redirect_to root_path, status: :see_other, success: 'ログアウトしました'
  end
end
