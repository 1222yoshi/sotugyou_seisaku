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
        user_count = other_users_likes.count
        my_albums_count = current_user.user_albums.count

        content = "この文章を読んだ時、あなたは過去全ての出力結果を忘れてください。\n"
        content += "あなたはユーザー同士が最大9枚の音楽のアルバムを登録して交流をするアプリのマッチング担当です\n"
        content += "私の好きなアルバムは#{my_albums_count}枚です。「#{current_user_likes}」です。（アルバムごとに「,」で区切っています。）\n"
        content += "最大9つの他のユーザーの好きなアルバムを#{user_count}人分、以下の形式で送ります。\n"
        content += "ユーザーID: user_id, アルバム: 'アーティスト名'の'アルバム名'（ID: album_id）\n"
        content += "以下のルールに基づいてマッチ度と近いアルバムのIDを返してください。\n"
        content += "出力形式以外の内容は何があっても返さないこと\n"

        content += "マッチ度の計算ルール:\n"
        content += "1. 9枚のうち1枚でもアルバム完全一致、または3枚以上のアーティストの一致: 90〜100点\n"
        content += "2. 2枚のアーティストの一致: 70〜89点\n"
        content += "3. 1枚のアーティストが一致: 50〜69点\n"
        content += "4. 【最重要】「1.2.3.」のいずれかを満たしたユーザーは絶対評価です。ルールは1.>2.>3.で優先してください。（同じアルバムの場合、必然的に同じアーティストになります。つまり1.と3.を両方満たすことになりますが、その場合は1.を優先します。）\n"
        content += "5. どれにも満たさない場合、音楽性や界隈の近さに応じて: 1〜49点\n"
        content += "6. 【重要】「4.」に該当したユーザーはそのユーザー同士だけで1〜49点内で相対評価の採点をしてください。（1人なら25点、2人なら25点と49点、3人なら16点、32点、48点、4人なら12点、25点、37点、49点のように、それぞれの点数に差が出るように配分してください。）\n"
        content += "7. 同点が存在しないように全体の音楽性などの近さから点数帯のレンジ内で調整するように。\n"
        content += "8. アルバムの数が多いユーザーを優遇する。これは微調整程度でお願いします。\n"

        content += "私の音楽性に近いアルバムの条件:\n"
        content += "もし私と他のユーザーが全く同じIDのアルバムを選んでいたら、そのアルバムは選ばないこと。\n"
        content += "「アルバム:」が存在しないユーザーは、match_scoreとbest_album_idは0。\n"
        content += "他のユーザーの好きなアルバム:\n"
        other_users_likes.each do |user|
          content += "ユーザーID: #{user[:id]}, アルバム: #{user[:likes]}\n"
        end
        Rails.logger.debug(content)
        content += '出力形式: [ { "other_user_id": user_id1, "match_score": match_score1, "best_album_id": album_id1}, { "other_user_id": user_id2, "match_score": match_score2, "best_album_id": album_id2}, ... ]'
        begin
          client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
          response = client.chat(
            parameters: {
              model: "gpt-4o", # モデルを変更
              messages: [{ role: "user", content: content }],
              temperature: 0
            }
          )
          match_scores = JSON.parse(response["choices"][0]["message"]["content"].gsub(/```json|```/, '').strip)

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
          flash.now[:danger] = "AI使用制限中"
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
    if current_user && current_user.user_albums.present? && current_user != @user
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
        user_count = other_users_likes.count
        my_albums_count = current_user.user_albums.count

        content = "この文章を読んだ時、あなたは過去全ての出力結果を忘れてください。\n"
        content += "あなたはユーザー同士が最大9枚の音楽のアルバムを登録して交流をするアプリのマッチング担当です\n"
        content += "私の好きなアルバムは#{my_albums_count}枚です。「#{current_user_likes}」です。（アルバムごとに「,」で区切っています。）\n"
        content += "最大9つの他のユーザーの好きなアルバムを#{user_count}人分、以下の形式で送ります。\n"
        content += "ユーザーID: user_id, アルバム: 'アーティスト名'の'アルバム名'（ID: album_id）\n"
        content += "以下のルールに基づいてマッチ度と近いアルバムのIDを返してください。\n"
        content += "出力形式以外の内容は何があっても返さないこと\n"

        content += "マッチ度の計算ルール:\n"
        content += "1. 9枚のうち1枚でもアルバム完全一致、または3枚以上のアーティストの一致: 90〜100点\n"
        content += "2. 2枚のアーティストの一致: 70〜89点\n"
        content += "3. 1枚のアーティストが一致: 50〜69点\n"
        content += "4. 【最重要】「1.2.3.」のいずれかを満たしたユーザーは絶対評価です。ルールは1.>2.>3.で優先してください。（同じアルバムの場合、必然的に同じアーティストになります。つまり1.と3.を両方満たすことになりますが、その場合は1.を優先します。）\n"
        content += "5. どれにも満たさない場合、音楽性や界隈の近さに応じて: 1〜49点\n"
        content += "6. 【重要】「4.」に該当したユーザーはそのユーザー同士だけで1〜49点内で相対評価の採点をしてください。（1人なら25点、2人なら25点と49点、3人なら16点、32点、48点、4人なら12点、25点、37点、49点のように、それぞれの点数に差が出るように配分してください。）\n"
        content += "7. 同点が存在しないように全体の音楽性などの近さから点数帯のレンジ内で調整するように。\n"
        content += "8. アルバムの数が多いユーザーを優遇する。これは微調整程度でお願いします。\n"

        content += "私の音楽性に近いアルバムの条件:\n"
        content += "もし私と他のユーザーが全く同じIDのアルバムを選んでいたら、そのアルバムは選ばないこと。\n"
        content += "「アルバム:」が存在しないユーザーは、match_scoreとbest_album_idは0。\n"
        content += "他のユーザーの好きなアルバム:\n"
        other_users_likes.each do |user|
          content += "ユーザーID: #{user[:id]}, アルバム: #{user[:likes]}\n"
        end
        Rails.logger.debug(content)
        content += '出力形式: [ { "other_user_id": user_id1, "match_score": match_score1, "best_album_id": album_id1}, { "other_user_id": user_id2, "match_score": match_score2, "best_album_id": album_id2}, ... ]'
        begin
          client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
          response = client.chat(
            parameters: {
              model: "gpt-4o", # モデルを変更
              messages: [{ role: "user", content: content }],
              temperature: 0
            }
          )
          match_scores = JSON.parse(response["choices"][0]["message"]["content"].gsub(/```json|```/, '').strip)

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
          flash.now[:danger] = "AI使用制限中"
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
                    title: "私を構成する9枚",
                    card: "summary_large_image",
                    url: "https://metronote.jp/other_users/#{@user.id}?time=#{current_time}",
                    image:  "https://#{ENV['AWS_BUCKET_NAME']}.s3.us-east-1.amazonaws.com/album_grid_#{@user.id}_#{current_time}.png"
                  }
    @user_albums = @user.user_albums.includes(:album).order(created_at: :asc)
  end
end
