class LikesController < ApplicationController
  def create
    @other_user_id = params[:liked_user_id]
    like = Like.find_by(like_user_id: current_user.id, liked_user_id: params[:liked_user_id])
    unless like.nil?
      like.destroy
      @action = 'destroy'
    else
      like = Like.create(like_user_id: current_user.id, liked_user_id: params[:liked_user_id])
      @action = 'create'
    end

    respond_to do |format|
      format.turbo_stream 
    end
  end

  def like_user
    @like_user_ids = Like.where(like_user_id: current_user.id).pluck(:liked_user_id)
    @q = User.where(id: @like_user_ids).ransack(params[:q])
    if current_user.like_music.present?
      @other_users = @q.result(distinct: true)
                    .joins("LEFT JOIN matches ON matches.other_user_id = users.id")
                    .where(matches: { user_id: current_user.id })
                    .select("users.*, matches.score as match_score")
                    .where.not(id: current_user.id)
                    .order('match_score DESC')
    else
      @other_users = @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .select('users.*, COUNT(user_albums.id) as albums_count')
                       .group('users.id')
                       .where.not(id: current_user.id)
                       .order('albums_count DESC')
    end
    if params[:areas_name].present?
      @other_users = @other_users.joins(:areas).where(areas: { id: params[:areas_name] })
    end
    if params[:instruments_name].present?
      @other_users = @other_users.joins(:instruments).where(instruments: { id: params[:instruments_name] })
    end
    if params[:purpose].present?
      @other_users = @other_users.where(users: { purpose: params[:purpose] })
    end
    @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
  end

  def liked_user
    @liked_user_ids = Like.where(liked_user_id: current_user.id).pluck(:like_user_id)
    @q = User.where(id: @liked_user_ids).ransack(params[:q])
    if current_user.like_music.present?
      @other_users = @q.result(distinct: true)
                    .joins("LEFT JOIN matches ON matches.other_user_id = users.id")
                    .where(matches: { user_id: current_user.id })
                    .select("users.*, matches.score as match_score")
                    .where.not(id: current_user.id)
                    .order('match_score DESC')
    else
      @other_users = @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .select('users.*, COUNT(user_albums.id) as albums_count')
                       .group('users.id')
                       .where.not(id: current_user.id)
                       .order('albums_count DESC')
    end
    if params[:areas_name].present?
      @other_users = @other_users.joins(:areas).where(areas: { id: params[:areas_name] })
    end
    if params[:instruments_name].present?
      @other_users = @other_users.joins(:instruments).where(instruments: { id: params[:instruments_name] })
    end
    if params[:purpose].present?
      @other_users = @other_users.where(users: { purpose: params[:purpose] })
    end
    @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
  end

  def match_user
    like_user_ids = Like.where(like_user_id: current_user.id).pluck(:liked_user_id)
    liked_user_ids = Like.where(liked_user_id: current_user.id).pluck(:like_user_id)
    @match_user_ids = like_user_ids & liked_user_ids
    @q = User.where(id: @match_user_ids).ransack(params[:q])
    if current_user.like_music.present?
      @other_users = @q.result(distinct: true)
                    .joins("LEFT JOIN matches ON matches.other_user_id = users.id")
                    .where(matches: { user_id: current_user.id })
                    .select("users.*, matches.score as match_score")
                    .where.not(id: current_user.id)
                    .order('match_score DESC')
    else
      @other_users = @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .select('users.*, COUNT(user_albums.id) as albums_count')
                       .group('users.id')
                       .where.not(id: current_user.id)
                       .order('albums_count DESC')
    end
    if params[:areas_name].present?
      @other_users = @other_users.joins(:areas).where(areas: { id: params[:areas_name] })
    end
    if params[:instruments_name].present?
      @other_users = @other_users.joins(:instruments).where(instruments: { id: params[:instruments_name] })
    end
    if params[:purpose].present?
      @other_users = @other_users.where(users: { purpose: params[:purpose] })
    end
    @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
  end
end
