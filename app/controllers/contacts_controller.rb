class ContactsController < ApplicationController
  def new
    @contact = Contact.new
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.save
      ContactMailer.send_mail(@contact, current_user).deliver_later
      redirect_to root_path, success: 'お問い合わせを送信しました。'
    else
      redirect_to new_contact_path, danger: '送信できませんでした。'
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:subject, :message)
  end
end
