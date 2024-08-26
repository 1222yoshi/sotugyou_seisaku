require 'json'
class OtherUsersController < ApplicationController
  skip_before_action :require_login, only: %i[index show]

  def index
    if current_user && current_user.user_albums.present?
      other_users = User.where.not(id: current_user.id)

      last_updated_time = Match.where(user_id: current_user.id, other_user_id: other_users.pluck(:id))
                               .group(:other_user_id)
                               .maximum(:updated_at)

      current_user_updated_time = UserAlbum.where(user_id: current_user.id)
                                           .maximum(:updated_at)
                                           
      other_user_updated_times = UserAlbum.where(user_id: other_users.pluck(:id))
                                          .group(:user_id)
                                          .maximum(:updated_at)

      recent_users = other_users.select do |user|
        last_updated_time[user.id].nil? || (other_user_updated_times[user.id].present? && other_user_updated_times[user.id] > last_updated_time[user.id]) || current_user_updated_time > last_updated_time[user.id] 
      end
    
      if recent_users.any?
        current_user_likes = current_user.like_music
        other_users_likes = recent_users.map { |user| { id: user.id, likes: user.like_music } }

        content = "私と他のユーザーとのマッチ度（0から100の範囲、点数には必ず一貫性を持ってください、ビートルズとオアシスのように違うアーティストでも音楽性や界隈、ルーツが近ければそれに準じた点数をつけてください、音楽がないユーザーは0点。）を以下の出力形式で返してください。それ以外を発言してしまうとエラーが起こります。\n"
        content += "私の好きな音楽: #{current_user_likes}\n"
        content += "他のユーザーの好きな音楽:\n"
        other_users_likes.each do |user|
          content += "ユーザーID: #{user[:id]}, 音楽: #{user[:likes]}\n"
        end
        content += '出力形式: [ { "other_user_id": user_id1, "match_score": match_score1}, { "other_user_id": user_id2, "match_score": match_score2}, ... ]'

        begin
          client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
          response = client.chat(
            parameters: {
              model: "gpt-4o-mini", # モデルを変更
              messages: [{ role: "user", content: content }],
              temperature: 0
            }
          )
          match_scores = JSON.parse(response["choices"][0]["message"]["content"])
   
          match_scores.each do |match|
            match_record = Match.find_or_initialize_by(
            user_id: current_user.id,
            other_user_id: match["other_user_id"]
          )
            match_record.score = match["match_score"]
            match_record.save
            match_record.touch
          end
        rescue Faraday::TooManyRequestsError => e
          flash.now[:danger] = "マッチ更新失敗、時間を置いてください。"
        rescue Faraday::ServerError => e
          flash.now[:danger] = "再試行してください。"  
        end
      end

      @other_users = User.joins("LEFT JOIN matches ON matches.other_user_id = users.id")
                    .where(matches: { user_id: current_user.id })
                    .where.not(id: current_user.id) # 自分以外のユーザーを取得
                    .distinct
                    .order('matches.score DESC')
                    .select("users.*, matches.score as match_score")
    elsif current_user
      @other_users = User.left_joins(:user_albums).group('users.id').where.not(id: current_user.id).order('COUNT(user_albums.id) DESC')
    else
      @other_users = User.left_joins(:user_albums).group('users.id').order('COUNT(user_albums.id) DESC')
    end
  end

  def show
    @user = User.find(params[:id])
    if current_user && current_user.user_albums.present?
      last_updated_time = Match.where(user_id: current_user.id, other_user_id: @user.id)
                               .maximum(:updated_at)

      current_user_updated_time = UserAlbum.where(user_id: current_user.id)
                                           .maximum(:updated_at)

      other_user_updated_times = UserAlbum.where(user_id: @user.id)
                                          .maximum(:updated_at)

      if last_updated_time.nil? || (other_user_updated_times.present? && other_user_updated_times > last_updated_time) || current_user_updated_time > last_updated_time
        current_user_likes = current_user.like_music
        other_user_likes = { id: @user.id, likes: @user.like_music }

        content = "私と他のユーザーとのマッチ度（0から100の範囲、点数には必ず一貫性を持ってください、ビートルズとオアシスのように違うアーティストでも音楽性や界隈、ルーツが近ければそれに準じた点数をつけてください、音楽がないユーザーは0点。）を以下の出力形式で返してください。それ以外を発言してしまうとエラーが起こります。\n"
        content += "私の好きな音楽: #{current_user_likes}\n"
        content += "他のユーザーの好きな音楽:\n"
        content += "ユーザーID: #{other_user_likes[:id]}, 音楽: #{other_user_likes[:likes]}\n"
        content += '出力形式: [ { "other_user_id": user_id, "match_score": match_score} ]'

        client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
        begin
          client = OpenAI::Client.new(access_token: )
          response = client.chat(
            parameters: {
              model: "gpt-4o-mini", # モデルを変更
              messages: [{ role: "user", content: content }],
              temperature: 0
            }
          )
          match_scores = JSON.parse(response["choices"][0]["message"]["content"])

          match_record = Match.find_or_initialize_by(
            user_id: current_user.id,
            other_user_id: match_scores[0]["other_user_id"]
          )
          match_record.score = match_scores[0]["match_score"]
          match_record.save
          match_record.touch
        rescue Faraday::TooManyRequestsError => e
          flash.now[:danger] = "マッチ更新失敗、時間を置いてください。"
        rescue Faraday::ServerError => e
          flash.now[:danger] = "再試行してください。"  
        end
      end
      @user = User
           .joins("LEFT JOIN matches ON matches.other_user_id = users.id AND matches.user_id = #{current_user.id}")
           .select("users.*, matches.score as match_score")
           .find(params[:id])
    end

    set_meta_tags   twitter: {
                    title: "＃私を構成する９枚",
                    card: "summary_large_image",
                    url: "https://metronote.jp/other_users/#{@user.id}",
                    image:  "https://metronote.jp/album_grid_#{@user.id}.png"
                  }
    @user_albums = @user.user_albums.includes(:album).order(created_at: :asc)
  end
end
