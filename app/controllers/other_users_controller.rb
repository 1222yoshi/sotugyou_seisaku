require 'json'
class OtherUsersController < ApplicationController
  skip_before_action :require_login, only: %i[index show]

  def index
    @q = User.ransack(params[:q])

    if current_user && current_user.user_albums.present?
      other_users = User.where.not(id: current_user.id)

      last_updated_time = Match.where(user_id: current_user.id)
                               .maximum(:updated_at)

      current_user_updated_time = UserAlbum.where(user_id: current_user.id)
                                           .maximum(:updated_at)
                                           
      other_user_updated_times = UserAlbum.where.not(user_id: current_user.id)
                                          .maximum(:updated_at)

      new_user_created_times = User.maximum(:created_at)      

      if last_updated_time.nil? || current_user_updated_time > last_updated_time || (other_user_updated_times.present? && other_user_updated_times) > last_updated_time || (new_user_created_times.present? && new_user_created_times > last_updated_time)
        like_artist_names = current_user.user_albums.includes(:album).map(&:album).map(&:artist_name).uniq
        like_users = other_users.select do |user|
          user.user_albums.includes(:album).any? { |ua| like_artist_names.include?(ua.album.artist_name) }
        end

        scores = Hash.new(0)

        like_users.each do |like_user|
          like_user_albums = like_user.user_albums.includes(:album)

          like_user_albums.each do |like_user_album|
            current_user.user_albums.each do |user_album|
              if like_user_album.album.album_name == user_album.album.album_name
                scores[like_user.id] += 10000
              elsif like_user_album.album.artist_name == user_album.album.artist_name
                scores[like_user.id] += 1000
              end
            end
          end
        end

        unknown_artist_names = like_users.flat_map do |user|
          user.user_albums.includes(:album).map(&:album).map(&:artist_name)
        end.uniq - like_artist_names

        unknown_artist_names.each do |artist_name|
          total_user_count = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).distinct.count(:user_id)
          like_user_count = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).where(user_id: like_users.map(&:id)).distinct.count(:user_id)
          next if total_user_count == 1
          if like_user_count == 1
            other_users_with_artist = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).where.not(user_id: like_users.map(&:id))
            other_users_with_artist.each do |ua|
              scores[ua.user_id] += 100
            end
          else
            total_users_with_artist = UserAlbum.joins(:album).where(albums: { artist_name: artist_name })
            total_users_with_artist.each do |ua|
              scores[ua.user_id] += 100
            end
          end
        end

        user_album_counts = UserAlbum.group(:user_id).count
        user_album_counts.each do |user_id, count|
          if scores.key?(user_id)
            scores[user_id] += count
          end
        end
        
        ruby_match = scores.map do |user_id, match_score|
          { "other_user_id" => user_id, "match_score" => match_score }
        end

        current_user_oldest_album_id = current_user.user_albums.order(:created_at).first&.album_id
        current_user_oldest_album = Album.find_by(id: current_user_oldest_album_id)
        current_user_likes = current_user_oldest_album&.artist_name 

        ruby_users = scores.map { |user_id, _| user_id }
        no_ruby_users = other_users.reject { |user| ruby_users.include?(user.id) }
        other_users_likes = no_ruby_users.map do |user|
          oldest_album_id = user.user_albums.order(:created_at).first&.album_id
          oldest_album = Album.find_by(id: oldest_album_id)
        
          {
            id: user.id,
            likes: oldest_album&.artist_name
          }
        end

        user_count = other_users_likes.count

        content = "あなたは過去全ての出力結果を忘れてください。\n"
        content += "あなたはユーザー同士が音楽のアーティストを登録して交流をするアプリのマッチング担当です\n"
        content += "私の好きなアーティストは「#{current_user_likes}」です。\n"
        content += "#{user_count}人分の、他のユーザーの好きなアーティストを以下の形式で送ります。\n"
        content += "ユーザーID: user_id, アーティスト: 'アーティスト名'\n"
        content += "以下のルールに基づいてマッチ度を返してください。\n"
        content += "「アーティスト:」が存在しないユーザーは0点を返す、以下の条件には含まない。\n"
        content += "採点基準は相対評価です、アーティストの類似を（ジャンル>国>年代）の基準で評価し、以下のように1〜99の間で分布が均等になるように点数をつけてください。\n"
        content += "対象者が1人なら必ず50点、2人なら必ず1人は1点、もう1人は99点、同様に3人なら[1点,50点,99点]、4人なら[1点,33点,66点,99点]、5人なら[1点,25点,50点,75点,99点]、この規則性。\n"
        content += "他のユーザーの好きなアーティスト:\n"
        other_users_likes.each do |user|
          content += "ユーザーID: #{user[:id]}, アーティスト: #{user[:likes]}\n"
        end
        Rails.logger.debug(content)
        content += '出力形式: [ { "other_user_id": user_id1, "match_score": match_score1}, { "other_user_id": user_id2, "match_score": match_score2}, ... ]'
        content += "出力形式以外の内容は何があっても返さないこと\n"
        begin
          client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
          response = client.chat(
            parameters: {
              model: "gpt-4o", # モデルを変更
              messages: [{ role: "user", content: content }],
              temperature: 0
            }
          )
          ai_match = JSON.parse(response["choices"][0]["message"]["content"].gsub(/```json|```/, '').strip)

          combined_match = ruby_match + ai_match
          combined_match.each do |match|
            match_record = Match.find_or_initialize_by(
            user_id: current_user.id,
            other_user_id: match["other_user_id"]
          )
            match_record.score = match["match_score"]
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
                    .select("users.*, matches.score as match_score")
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
      other_users = User.where.not(id: current_user.id)

      last_updated_time = Match.where(user_id: current_user.id)
                               .maximum(:updated_at)

      current_user_updated_time = UserAlbum.where(user_id: current_user.id)
                                           .maximum(:updated_at)
                                           
      other_user_updated_times = UserAlbum.where.not(user_id: current_user.id)
                                          .maximum(:updated_at)

      new_user_created_times = User.maximum(:created_at)      

      if last_updated_time.nil? || current_user_updated_time > last_updated_time || (other_user_updated_times.present? && other_user_updated_times) > last_updated_time || (new_user_created_times.present? && new_user_created_times > last_updated_time)
        like_artist_names = current_user.user_albums.includes(:album).map(&:album).map(&:artist_name).uniq
        like_users = other_users.select do |user|
          user.user_albums.includes(:album).any? { |ua| like_artist_names.include?(ua.album.artist_name) }
        end

        scores = Hash.new(0)

        like_users.each do |like_user|
          like_user_albums = like_user.user_albums.includes(:album)

          like_user_albums.each do |like_user_album|
            current_user.user_albums.each do |user_album|
              if like_user_album.album.album_name == user_album.album.album_name
                scores[like_user.id] += 10000
              elsif like_user_album.album.artist_name == user_album.album.artist_name
                scores[like_user.id] += 1000
              end
            end
          end
        end

        unknown_artist_names = like_users.flat_map do |user|
          user.user_albums.includes(:album).map(&:album).map(&:artist_name)
        end.uniq - like_artist_names

        unknown_artist_names.each do |artist_name|
          total_user_count = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).distinct.count(:user_id)
          like_user_count = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).where(user_id: like_users.map(&:id)).distinct.count(:user_id)
          next if total_user_count == 1
          if like_user_count == 1
            other_users_with_artist = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).where.not(user_id: like_users.map(&:id))
            other_users_with_artist.each do |ua|
              scores[ua.user_id] += 100
            end
          else
            total_users_with_artist = UserAlbum.joins(:album).where(albums: { artist_name: artist_name })
            total_users_with_artist.each do |ua|
              scores[ua.user_id] += 100
            end
          end
        end

        user_album_counts = UserAlbum.group(:user_id).count
        user_album_counts.each do |user_id, count|
          if scores.key?(user_id)
            scores[user_id] += count
          end
        end

        ruby_match = scores.map do |user_id, match_score|
          { "other_user_id" => user_id, "match_score" => match_score }
        end

        current_user_oldest_album_id = current_user.user_albums.order(:created_at).first&.album_id
        current_user_oldest_album = Album.find_by(id: current_user_oldest_album_id)
        current_user_likes = current_user_oldest_album&.artist_name 

        ruby_users = scores.map { |user_id, _| user_id }
        no_ruby_users = other_users.reject { |user| ruby_users.include?(user.id) }
        other_users_likes = no_ruby_users.map do |user|
          oldest_album_id = user.user_albums.order(:created_at).first&.album_id
          oldest_album = Album.find_by(id: oldest_album_id)
        
          {
            id: user.id,
            likes: oldest_album&.artist_name
          }
        end

        user_count = other_users_likes.count

        content = "あなたは過去全ての出力結果を忘れてください。\n"
        content += "あなたはユーザー同士が音楽のアーティストを登録して交流をするアプリのマッチング担当です\n"
        content += "私の好きなアーティストは「#{current_user_likes}」です。\n"
        content += "#{user_count}人分の、他のユーザーの好きなアーティストを以下の形式で送ります。\n"
        content += "ユーザーID: user_id, アーティスト: 'アーティスト名'\n"
        content += "以下のルールに基づいてマッチ度を返してください。\n"
        content += "「アーティスト:」が存在しないユーザーは0点を返す、以下の条件には含まない。\n"
        content += "採点基準は相対評価です、アーティストの類似を（ジャンル>国>年代）の基準で評価し、以下のように1〜99の間で分布が均等になるように点数をつけてください。\n"
        content += "対象者が1人なら必ず50点、2人なら必ず1人は1点、もう1人は99点、同様に3人なら[1点,50点,99点]、4人なら[1点,33点,66点,99点]、5人なら[1点,25点,50点,75点,99点]、この規則性。\n"
        content += "他のユーザーの好きなアーティスト:\n"
        other_users_likes.each do |user|
          content += "ユーザーID: #{user[:id]}, アーティスト: #{user[:likes]}\n"
        end
        Rails.logger.debug(content)
        content += '出力形式: [ { "other_user_id": user_id1, "match_score": match_score1}, { "other_user_id": user_id2, "match_score": match_score2}, ... ]'
        content += "出力形式以外の内容は何があっても返さないこと\n"
        begin
          client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
          response = client.chat(
            parameters: {
              model: "gpt-4o", # モデルを変更
              messages: [{ role: "user", content: content }],
              temperature: 0
            }
          )
          ai_match = JSON.parse(response["choices"][0]["message"]["content"].gsub(/```json|```/, '').strip)

          combined_match = ruby_match + ai_match
          combined_match.each do |match|
            match_record = Match.find_or_initialize_by(
            user_id: current_user.id,
            other_user_id: match["other_user_id"]
          )
            match_record.score = match["match_score"]
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
                  .select("users.*, matches.score as match_score")
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
