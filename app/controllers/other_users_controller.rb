require 'json'
class OtherUsersController < ApplicationController
  skip_before_action :require_login, only: %i[index show]

  def index
    @q = User.ransack(params[:q])

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

        content = "私と他のユーザーとのマッチ度とその相手のユーザーの最大9枚のアルバムの中で一番私の音楽性に近いアルバムのidを一つ以下の【出力形式:】より後に書いてあるの配列の形で返してください。それ以外の発言は絶対にしないでください。\n"
        content += "私の好きな音楽: #{current_user_likes}\n"
        content += "他のユーザーの好きな音楽:\n"
        other_users_likes.each do |user|
          content += "ユーザーID: #{user[:id]}, 音楽: #{user[:likes]}\n"
        end
        content += '条件: match_scoreは後述する条件を除いて絶対に1から100の範囲、ビートルズとオアシスのように違うアーティストでも音楽性や界隈、ルーツが近ければそれに準じた点数をつけてください、同じアーティストの組み合わせでユーザーごとに点数のばらつきが出ないように採点基準の一貫性を強く持ってください。best_album_idはもし私と他のユーザーが全く同じidのアルバムを選んでいたら、そのアルバムは絶対に選ばないでください、アルバムが一枚でもある限りはマッチ度が1だったとしても、最大9枚から私と全く同じ音楽以外で一番共通点のある一枚を選んで絶対にidを返してください。【音楽:】の後に文章が存在しないユーザーはmatch_score、best_album_idともに0を返してください。'
        content += '出力形式: [ { "other_user_id": user_id1, "match_score": match_score1, "best_album_id": album_id1}, { "other_user_id": user_id2, "match_score": match_score2, "best_album_id": album_id2}, ... ]'
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
            match_record.match_album = match["best_album_id"]
            if match_record.save
              match_record.touch
              flash.now[:success] = "マッチ情報を更新しました。"
            end
          end
        rescue Faraday::TooManyRequestsError => e
          flash.now[:danger] = "マッチ情報の更新に失敗しました。"
        rescue JSON::ParserError => each
          flash.now[:danger] = "AIが予期せぬ返答をしました。"
        rescue Faraday::ServerError => e
          flash.now[:danger] = "再試行してください。"  
        end
      end

      @other_users = @q.result(distinct: true)
                    .joins("LEFT JOIN matches ON matches.other_user_id = users.id")
                    .where(matches: { user_id: current_user.id })
                    .select("users.*, matches.score as match_score, matches.match_album")
                    .where.not(id: current_user.id)
                    .order('match_score DESC')

    elsif current_user
      @other_users = @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .select('users.*, COUNT(user_albums.id) as albums_count')
                       .group('users.id')
                       .where.not(id: current_user.id)
                       .order('albums_count DESC')
    else
      @other_users = @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .select('users.*, COUNT(user_albums.id) as albums_count')
                       .group('users.id')
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
  end

  def show
    @user = User.find(params[:id])
    if current_user && current_user.user_albums.present? && current_user != @user
      last_updated_time = Match.where(user_id: current_user.id, other_user_id: @user.id)
                               .maximum(:updated_at)

      current_user_updated_time = UserAlbum.where(user_id: current_user.id)
                                           .maximum(:updated_at)

      other_user_updated_times = UserAlbum.where(user_id: @user.id)
                                          .maximum(:updated_at)

      if last_updated_time.nil? || (other_user_updated_times.present? && other_user_updated_times > last_updated_time) || current_user_updated_time > last_updated_time
        current_user_likes = current_user.like_music
        other_user_likes = { id: @user.id, likes: @user.like_music }

        content = "私と他のユーザーとのマッチ度とその相手のユーザーの最大9枚のアルバムの中で一番私の音楽性に近いアルバムのidを一つ以下の【出力形式:】より後に書いてあるの配列の形で返してください。それ以外の発言は絶対にしないでください。\n"
        content += "私の好きな音楽: #{current_user_likes}\n"
        content += "他のユーザーの好きな音楽:\n"
        content += "ユーザーID: #{other_user_likes[:id]}, 音楽: #{other_user_likes[:likes]}\n"
        content += '条件: match_scoreは後述する条件を除いて絶対に1から100の範囲、ビートルズとオアシスのように違うアーティストでも音楽性や界隈、ルーツが近ければそれに準じた点数をつけてください、同じアーティストの組み合わせでユーザーごとに点数のばらつきが出ないように採点基準の一貫性を強く持ってください。best_album_idはもし私と他のユーザーが全く同じidのアルバムを選んでいたら、そのアルバムは絶対に選ばないでください、アルバムが一枚でもある限りはマッチ度が1だったとしても、最大9枚から私と全く同じ音楽以外で一番共通点のある一枚を選んで絶対にidを返してください。【音楽:】の後に文章が存在しないユーザーはmatch_score、best_album_idともに0を返してください。'
        content += '出力形式: [ { "other_user_id": user_id, "match_score": match_score, "best_album_id": album_id} ]'

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

          match_record = Match.find_or_initialize_by(
            user_id: current_user.id,
            other_user_id: match_scores[0]["other_user_id"]
          )
          match_record.score = match_scores[0]["match_score"]
          match_record.match_album = match_scores[0]["best_album_id"]
          if match_record.save
            match_record.touch
            flash.now[:success] = "マッチ情報を更新しました。"
          end
        rescue Faraday::TooManyRequestsError => e
          flash.now[:danger] = "マッチ更新失敗、時間を置いてください。"
        rescue JSON::ParserError => each
          flash.now[:danger] = "AIが予期せぬ返答をしました。"
        rescue Faraday::ServerError => e
          flash.now[:danger] = "再試行してください。"  
        end
      end
      @user = User.joins("LEFT JOIN matches ON matches.other_user_id = users.id AND matches.user_id = #{current_user.id}")
                  .select("users.*, matches.score as match_score, matches.match_album")
                  .find(params[:id])
    end

    if current_user == @user
      redirect_to profile_path
    end

    current_time = params[:time]
    set_meta_tags   twitter: {
                    title: "MeTRO NOTE",
                    card: "summary_large_image",
                    url: "https://metronote.jp/other_users/#{@user.id}?time=#{current_time}",
                    image:  "https://#{ENV['AWS_BUCKET_NAME']}.s3.us-east-1.amazonaws.com/album_grid_#{@user.id}_#{current_time}.png"
                  }
    @user_albums = @user.user_albums.includes(:album).order(created_at: :asc)
  end
end
