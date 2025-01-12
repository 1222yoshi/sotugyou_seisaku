class LikesController < ApplicationController
  def create
    @other_user_id = params[:liked_user_id]
    like = Like.find_by(like_user_id: current_user.id, liked_user_id: params[:liked_user_id])
    if like.nil?
      Like.create(like_user_id: current_user.id, liked_user_id: params[:liked_user_id])
      unless Notification.exists?(user_id: params[:liked_user_id], source_user_id: current_user.id)
        Notification.create(user_id: params[:liked_user_id], source_user_id: current_user.id, notification_type: 'like')
      end
      @action = 'create'
    else
      like.destroy
      @action = 'destroy'
      notification = Notification.find_by(user_id: params[:liked_user_id], source_user_id: current_user.id)
      notification.destroy if notification && !notification.is_read
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def like_user
    @like_user_ids = Like.where(like_user_id: current_user.id).pluck(:liked_user_id)
    @q = User.where(id: @like_user_ids).ransack(params[:q])
    @other_users = if current_user.like_music.present?
                     @q.result(distinct: true)
                       .joins('LEFT JOIN matches ON matches.other_user_id = users.id')
                       .where(matches: { user_id: current_user.id })
                       .select('users.*, matches.score as match_score')
                       .where.not(id: current_user.id)
                       .order('match_score DESC')
                   else
                     @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .select('users.*, COUNT(user_albums.id) as albums_count')
                       .group('users.id')
                       .where.not(id: current_user.id)
                       .order('albums_count DESC')
                   end
    @other_users = @other_users.joins(:areas).where(areas: { id: params[:areas_name] }) if params[:areas_name].present?
    if params[:instruments_name].present?
      @other_users = @other_users.joins(:instruments).where(instruments: { id: params[:instruments_name] })
    end
    @other_users = @other_users.where(users: { purpose: params[:purpose] }) if params[:purpose].present?
    @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
  end

  def liked_user
    Notification.where(user_id: current_user.id, notification_type: 'like').update_all(is_read: true)
    @liked_user_ids = Like.where(liked_user_id: current_user.id).pluck(:like_user_id)
    @q = User.where(id: @liked_user_ids).ransack(params[:q])
    @other_users = if current_user.like_music.present?
                     @q.result(distinct: true)
                       .joins('LEFT JOIN matches ON matches.other_user_id = users.id')
                       .where(matches: { user_id: current_user.id })
                       .select('users.*, matches.score as match_score')
                       .where.not(id: current_user.id)
                       .order('match_score DESC')
                   else
                     @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .select('users.*, COUNT(user_albums.id) as albums_count')
                       .group('users.id')
                       .where.not(id: current_user.id)
                       .order('albums_count DESC')
                   end
    @other_users = @other_users.joins(:areas).where(areas: { id: params[:areas_name] }) if params[:areas_name].present?
    if params[:instruments_name].present?
      @other_users = @other_users.joins(:instruments).where(instruments: { id: params[:instruments_name] })
    end
    @other_users = @other_users.where(users: { purpose: params[:purpose] }) if params[:purpose].present?
    @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
  end

  def match_user
    Notification.where(user_id: current_user.id, notification_type: 'like').update_all(is_read: true)
    like_user_ids = Like.where(like_user_id: current_user.id).pluck(:liked_user_id)
    liked_user_ids = Like.where(liked_user_id: current_user.id).pluck(:like_user_id)
    @match_user_ids = like_user_ids & liked_user_ids
    @q = User.where(id: @match_user_ids).ransack(params[:q])
    @other_users = if current_user.like_music.present?
                     @q.result(distinct: true)
                       .joins('LEFT JOIN matches ON matches.other_user_id = users.id')
                       .where(matches: { user_id: current_user.id })
                       .select('users.*, matches.score as match_score')
                       .where.not(id: current_user.id)
                       .order('match_score DESC')
                   else
                     @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .select('users.*, COUNT(user_albums.id) as albums_count')
                       .group('users.id')
                       .where.not(id: current_user.id)
                       .order('albums_count DESC')
                   end
    @other_users = @other_users.joins(:areas).where(areas: { id: params[:areas_name] }) if params[:areas_name].present?
    if params[:instruments_name].present?
      @other_users = @other_users.joins(:instruments).where(instruments: { id: params[:instruments_name] })
    end
    @other_users = @other_users.where(users: { purpose: params[:purpose] }) if params[:purpose].present?
    @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
  end
end
