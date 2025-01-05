class ContactMailer < ApplicationMailer
  def send_mail(contact, user)
    @user = user
    @contact = contact
    mail(to: ENV['MY_MAIL_ADDRESS'], subject: "【お問い合わせ】" + @contact.subject)
  end
end
