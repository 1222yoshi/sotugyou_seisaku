class ChatroomsController < ApplicationController
  def index
    @q = User.ransack(params[:q])
    searched_users = @q.result.where.not(id: current_user.id)

    @chatrooms = current_user.chatrooms_as_user_1.or(current_user.chatrooms_as_user_2)
                .joins(:messages)
                .select('chatrooms.*, MAX(messages.created_at) AS latest_message_time')
                .where('user_1_id IN (?) OR user_2_id IN (?)', searched_users.pluck(:id), searched_users.pluck(:id)) 
                .group('chatrooms.id')
                .order('latest_message_time DESC')
  end

  def create
    @other_user = User.find(params[:id])
    @chatroom = Chatroom.where("user_1_id = ? AND user_2_id = ? OR user_1_id = ? AND user_2_id = ?", current_user.id, @other_user.id, @other_user.id, current_user.id).first
    unless @chatroom
      @chatroom = Chatroom.create(user_1_id: current_user.id, user_2_id: @other_user.id)
    end
    redirect_to chatroom_path(@chatroom) and return
  end

  def show
    @chatroom = Chatroom.find(params[:id])
    unless @chatroom.user_1_id == current_user.id || @chatroom.user_2_id == current_user.id
      redirect_to root_path
    end
    @match = Match.find_by(user_id: current_user.id, other_user_id: @chatroom.other_user(current_user).id)
    Notification.where(user_id: current_user.id, source_user_id: @chatroom.other_user(current_user).id, notification_type: "message").update_all(is_read: true)
    @messages = @chatroom.messages.includes(:user)
    @message = Message.new
    @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
  end

  def post_message
    @chatroom = Chatroom.find(params[:id])
    @message = @chatroom.messages.build(message_params)
    if @message.body.present?
      @message.user = current_user
      unless current_user.profile_image_url.nil?
        img = current_user.profile_image_url
      else
        img = 'me-4414548e6f4cf95a9be7fb8c2b780005f376419ca47bf32f6d6a185a7d472db6.png'
      end
    
      if @message.save
        Rails.logger.debug(img)
        ActionCable.server.broadcast "message_#{current_user.id}", { message: @message}
        ActionCable.server.broadcast "message_#{@chatroom.other_user(current_user).id}", { message: @message, other_user_img: img, other_user_id: current_user.id }
        Notification.create(user_id: @chatroom.other_user(current_user).id, source_user_id: current_user.id, notification_type: "message")
      end
      head :ok
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
