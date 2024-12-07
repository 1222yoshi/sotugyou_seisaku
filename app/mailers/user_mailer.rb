class UserMailer < ApplicationMailer
  default from: "#{ENV['GMAIL_ADDRESS']}"

  def reset_password_email(user)
    @user = User.find(user.id)
    @url = edit_password_reset_url(@user.reset_password_token)
    mail(to: user.email, subject: "パスワードリセット")
  end

  def reset_email_email(user)
    @user = User.find(user.id)
    @url = pass_email_reset_url(@user.reset_email_token)
    mail(to: user.reset_email, subject: "メールアドレス変更")
  end
end
