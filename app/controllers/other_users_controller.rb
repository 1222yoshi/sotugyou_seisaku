require 'json'
class OtherUsersController < ApplicationController
  skip_before_action :require_login, only: %i[index show quiz_result]

  def index
    @q = User.ransack(params[:q])
    if current_user && current_user.like_music.present?
      other_users = User.where.not(id: current_user.id)

      last_updated_time = Match.where(user_id: current_user.id)
                               .maximum(:updated_at)

      current_user_updated_time = UserAlbum.where(user_id: current_user.id)
                                           .maximum(:updated_at)

      other_user_updated_times = UserAlbum.where.not(user_id: current_user.id)
                                          .maximum(:updated_at)

      new_user_created_times = User.maximum(:created_at)

      if last_updated_time.nil? || current_user_updated_time > last_updated_time || (other_user_updated_times.present? && other_user_updated_times) > last_updated_time || (new_user_created_times.present? && new_user_created_times > last_updated_time)
        like_artist_names = current_user.user_albums.includes(:album).map(&:album).map(&:artist_name).uniq.reject do |artist_name|
          artist_name == 'Various Artists'
        end
        like_users = other_users.select do |user|
          user.user_albums.includes(:album).any? { |ua| like_artist_names.include?(ua.album.artist_name) }
        end

        scores = Hash.new(0)

        like_users.each do |like_user|
          like_user_albums = like_user.user_albums.includes(:album)

          like_user_albums.each do |like_user_album|
            next if like_user_album.album.artist_name == 'Various Artists'

            album_match = false
            current_user.user_albums.each do |user_album|
              next unless like_user_album.album.album_name == user_album.album.album_name

              scores[like_user.id] += 100_000
              album_match = true
              break
            end
            next if album_match

            current_user.user_albums.each do |user_album|
              if like_user_album.album.artist_name == user_album.album.artist_name
                scores[like_user.id] += 10_000
                break
              end
            end
          end
        end

        unknown_artist_names = like_users.flat_map do |user|
          user.user_albums.includes(:album).map(&:album).map(&:artist_name)
        end.uniq.reject { |artist_name| artist_name == 'Various Artists' } - like_artist_names

        unknown_artist_names.each do |artist_name|
          total_user_count = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).distinct.count(:user_id)
          like_user_count = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).where(user_id: like_users.map(&:id)).distinct.count(:user_id)
          next if total_user_count == 1

          if like_user_count == 1
            other_users_with_artist = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).where.not(user_id: like_users.map(&:id))
            other_users_with_artist.each do |ua|
              scores[ua.user_id] += 1000
            end
          else
            total_users_with_artist = UserAlbum.joins(:album).where(albums: { artist_name: artist_name })
            total_users_with_artist.each do |ua|
              scores[ua.user_id] += 1000
            end
          end
        end

        user_album_counts = UserAlbum.group(:user_id).count
        user_album_counts.each do |user_id, count|
          scores[user_id] += count if scores.key?(user_id)
        end

        ruby_match = scores.map do |user_id, match_score|
          { 'other_user_id' => user_id, 'match_score' => match_score }
        end

        current_user_likes = current_user.like_music
        ruby_users = scores.map { |user_id, _| user_id }
        no_ruby_users = other_users.reject { |user| ruby_users.include?(user.id) }
        empty_likes_users = no_ruby_users.select do |user|
          user.like_music.nil?
        end
        other_users_likes = no_ruby_users.reject { |user| empty_likes_users.include?(user) }.map do |user|
          {
            id: user.id,
            likes: user.like_music
          }
        end
        empty_likes_users.each do |user|
          ruby_match << { 'other_user_id' => user.id, 'match_score' => 0 }
        end
        @user_count = other_users_likes.count

        content = "私の音楽性は「#{current_user_likes}」です。\n"
        content += "#{@user_count}人分の、他のユーザーのIDと音楽性を送ります。\n"
        content += "以下のルールに基づいて私とのマッチ度をIDと一緒に返してください。\n"
        content += "採点基準は相対評価で、音楽性（評価基準：文化的背景>音像的特徴>年代と地域）の近いアーティストを評価して採点してください。\n"
        content += "得点は1〜#{@user_count}の範囲で、一番音楽性が遠いユーザーは必ず1点、一番音楽性の近いのユーザーは必ず#{@user_count}点とし、必ず連番で並べてください。（同じ点数のユーザーは一人も作らないこと。）\n"
        content += '今回渡されたIDのユーザーにのみ採点を返してください。'
        content += "他のユーザーの音楽性:\n"
        other_users_likes.each do |user|
          content += "ユーザーID: #{user[:id]}, 音楽性: #{user[:likes]}\n"
        end
        Rails.logger.debug(content)
        content += '出力形式: [ { "other_user_id": user_id1, "match_score": match_score1}, { "other_user_id": user_id2, "match_score": match_score2}, ... ]'
        content += "出力形式以外の内容は何があっても返さないこと\n"
        begin
          client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
          response = client.chat(
            parameters: {
              model: 'gpt-4o-mini', # モデルを変更
              messages: [{ role: 'user', content: content }],
              temperature: 0
            }
          )
          ai_match = JSON.parse(response['choices'][0]['message']['content'].gsub(/```json|```/, '').strip)

          combined_match = ruby_match + ai_match
          combined_match.each do |match|
            match_record = Match.find_or_initialize_by(
              user_id: current_user.id,
              other_user_id: match['other_user_id']
            )
            match_record.score = match['match_score']
            if match_record.save
              match_record.touch
              flash.now[:success] = 'マッチ情報を更新しました。'
            end
          end
        rescue Faraday::TooManyRequestsError
          flash.now[:danger] = 'AI使用制限中'
        rescue JSON::ParserError
          flash.now[:danger] = 'AIが予期せぬ返答をしました。'
        rescue Faraday::ServerError
          flash.now[:danger] = '再試行してください。'
        end
      end
      @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
      like_user_ids = Like.where(like_user_id: current_user.id).pluck(:liked_user_id)
      liked_user_ids = Like.where(liked_user_id: current_user.id).pluck(:like_user_id)
      notification_user_ids = Notification.where(user_id: current_user.id, is_read: false, notification_type: "message").pluck(:source_user_id)
      @other_users = @q.result(distinct: true)
                       .joins('LEFT JOIN matches ON matches.other_user_id = users.id')
                       .includes(:areas, :instruments, user_albums: :album)
                       .where(matches: { user_id: current_user.id })
                       .select('users.*, 
                                matches.score as match_score, 
                                (SELECT MAX(rank_score) FROM results WHERE user_id = users.id AND clear = true) AS max_rank_score,
                                (SELECT COUNT(*) FROM user_albums WHERE user_id = users.id) AS album_count')
                       .where.not(id: current_user.id)
                       .order('match_score DESC')
                       .tap do |users|
                        users.each do |user|
                          user.i_like = like_user_ids.include?(user.id)
                          user.i_liked = liked_user_ids.include?(user.id)
                          user.notification_now = notification_user_ids.include?(user.id)
                        end
                      end
    elsif current_user
      like_user_ids = Like.where(like_user_id: current_user.id).pluck(:liked_user_id)
      liked_user_ids = Like.where(liked_user_id: current_user.id).pluck(:like_user_id)
      notification_user_ids = Notification.where(user_id: current_user.id, is_read: false, notification_type: "message").pluck(:source_user_id)
      @other_users = @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .includes(:areas, :instruments, user_albums: :album)
                       .select('users.*, 
                                COUNT(user_albums.id) as albums_count,
                                (SELECT MAX(rank_score) FROM results WHERE user_id = users.id AND clear = true) AS max_rank_score,
                                (SELECT COUNT(*) FROM user_albums WHERE user_id = users.id) AS album_count')
                       .group('users.id')
                       .where.not(id: current_user.id)
                       .order('albums_count DESC')
                       .tap do |users|
                        users.each do |user|
                          user.i_like = like_user_ids.include?(user.id)
                          user.i_liked = liked_user_ids.include?(user.id)
                          user.notification_now = notification_user_ids.include?(user.id)
                        end
                      end
      flash.now[:success] = '私を構成する9枚を作りましょう'
    else
      @other_users = @q.result(distinct: true)
                       .left_joins(:user_albums)
                       .includes(:areas, :instruments, user_albums: :album)
                       .select('users.*, 
                                COUNT(user_albums.id) as albums_count,
                                (SELECT MAX(rank_score) FROM results WHERE user_id = users.id AND clear = true) AS max_rank_score,
                                (SELECT COUNT(*) FROM user_albums WHERE user_id = users.id) AS album_count')
                       .group('users.id')
                       .order('albums_count DESC')
    end

    @other_users = @other_users.left_joins(:areas).where(areas: { id: params[:areas_name] }) if params[:areas_name].present?

    if params[:instruments_name].present?
      @other_users = @other_users.left_joins(:instruments).where(instruments: { id: params[:instruments_name] })
    end

    if params[:purpose].present?
      @other_users = @other_users.where(users: { purpose: params[:purpose] })
    end
  end

  def quiz_result
    @q = User.ransack(params[:q])
    if current_user && current_user.like_music.present?
      @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
      like_user_ids = Like.where(like_user_id: current_user.id).pluck(:liked_user_id)
      liked_user_ids = Like.where(liked_user_id: current_user.id).pluck(:like_user_id)
      notification_user_ids = Notification.where(user_id: current_user.id, is_read: false, notification_type: "message").pluck(:source_user_id)
      @other_users = @q.result(distinct: true)
                       .left_joins(:results)
                       .joins('LEFT JOIN matches ON matches.other_user_id = users.id')
                       .includes(:areas, :instruments, user_albums: :album)
                       .where(matches: { user_id: current_user.id })
                       .where.not(id: current_user.id)
                       .group('users.id, matches.score')
                       .select('users.*, COALESCE(MAX(CASE WHEN results.clear = true THEN results.rank_score ELSE NULL END), 0) AS max_rank_score, matches.score AS match_score, 
                                (SELECT COUNT(*) FROM user_albums WHERE user_id = users.id) AS album_count')
                       .order('max_rank_score DESC')
                       .tap do |users|
                        users.each do |user|
                          user.i_like = like_user_ids.include?(user.id)
                          user.i_liked = liked_user_ids.include?(user.id)
                          user.notification_now = notification_user_ids.include?(user.id)
                        end
                      end
    elsif current_user
      like_user_ids = Like.where(like_user_id: current_user.id).pluck(:liked_user_id)
      liked_user_ids = Like.where(liked_user_id: current_user.id).pluck(:like_user_id)
      notification_user_ids = Notification.where(user_id: current_user.id, is_read: false, notification_type: "message").pluck(:source_user_id)
      @other_users = @q.result(distinct: true)
                       .left_joins(:results) # LEFT JOIN に変更
                       .includes(:areas, :instruments, user_albums: :album)
                       .where.not(id: current_user.id)
                       .group('users.id')
                       .select('users.*, COALESCE(MAX(CASE WHEN results.clear = true THEN results.rank_score ELSE NULL END), 0) AS max_rank_score, 
                                (SELECT COUNT(*) FROM user_albums WHERE user_id = users.id) AS album_count') # clearがtrueのrank_scoreのみ取得
                       .order('max_rank_score DESC')
                       .tap do |users|
                        users.each do |user|
                          user.i_like = like_user_ids.include?(user.id)
                          user.i_liked = liked_user_ids.include?(user.id)
                          user.notification_now = notification_user_ids.include?(user.id)
                        end
                      end
    else
      @other_users = @q.result(distinct: true)
                       .left_joins(:results) # LEFT JOIN に変更
                       .group('users.id')
                       .select('users.*, COALESCE(MAX(CASE WHEN results.clear = true THEN results.rank_score ELSE NULL END), 0) AS max_rank_score, 
                                (SELECT COUNT(*) FROM user_albums WHERE user_id = users.id) AS album_count') # clearがtrueのrank_scoreのみ取得
                       .order('max_rank_score DESC')
    end

    @other_users = @other_users.left_joins(:areas).where(areas: { id: params[:areas_name] }) if params[:areas_name].present?

    if params[:instruments_name].present?
      @other_users = @other_users.left_joins(:instruments).where(instruments: { id: params[:instruments_name] })
    end

    return unless params[:purpose].present?

    @other_users = @other_users.where(users: { purpose: params[:purpose] })
  end

  def show
    @user = User.find(params[:id])
    if current_user && current_user.like_music.present? && current_user != @user
      other_users = User.where.not(id: current_user.id)

      last_updated_time = Match.where(user_id: current_user.id)
                               .maximum(:updated_at)

      current_user_updated_time = UserAlbum.where(user_id: current_user.id)
                                           .maximum(:updated_at)

      other_user_updated_times = UserAlbum.where.not(user_id: current_user.id)
                                          .maximum(:updated_at)

      new_user_created_times = User.maximum(:created_at)

      if last_updated_time.nil? || current_user_updated_time > last_updated_time || (other_user_updated_times.present? && other_user_updated_times) > last_updated_time || (new_user_created_times.present? && new_user_created_times > last_updated_time)
        like_artist_names = current_user.user_albums.includes(:album).map(&:album).map(&:artist_name).uniq.reject do |artist_name|
          artist_name == 'Various Artists'
        end
        like_users = other_users.select do |user|
          user.user_albums.includes(:album).any? { |ua| like_artist_names.include?(ua.album.artist_name) }
        end

        scores = Hash.new(0)

        like_users.each do |like_user|
          like_user_albums = like_user.user_albums.includes(:album)

          like_user_albums.each do |like_user_album|
            next if like_user_album.album.artist_name == 'Various Artists'

            album_match = false
            current_user.user_albums.each do |user_album|
              next unless like_user_album.album.album_name == user_album.album.album_name

              scores[like_user.id] += 100_000
              album_match = true
              break
            end
            next if album_match

            current_user.user_albums.each do |user_album|
              if like_user_album.album.artist_name == user_album.album.artist_name
                scores[like_user.id] += 10_000
                break
              end
            end
          end
        end

        unknown_artist_names = like_users.flat_map do |user|
          user.user_albums.includes(:album).map(&:album).map(&:artist_name)
        end.uniq.reject { |artist_name| artist_name == 'Various Artists' } - like_artist_names

        unknown_artist_names.each do |artist_name|
          total_user_count = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).distinct.count(:user_id)
          like_user_count = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).where(user_id: like_users.map(&:id)).distinct.count(:user_id)
          next if total_user_count == 1

          if like_user_count == 1
            other_users_with_artist = UserAlbum.joins(:album).where(albums: { artist_name: artist_name }).where.not(user_id: like_users.map(&:id))
            other_users_with_artist.each do |ua|
              scores[ua.user_id] += 1000
            end
          else
            total_users_with_artist = UserAlbum.joins(:album).where(albums: { artist_name: artist_name })
            total_users_with_artist.each do |ua|
              scores[ua.user_id] += 1000
            end
          end
        end

        user_album_counts = UserAlbum.group(:user_id).count
        user_album_counts.each do |user_id, count|
          scores[user_id] += count if scores.key?(user_id)
        end

        ruby_match = scores.map do |user_id, match_score|
          { 'other_user_id' => user_id, 'match_score' => match_score }
        end

        current_user_likes = current_user.like_music
        ruby_users = scores.map { |user_id, _| user_id }
        no_ruby_users = other_users.reject { |user| ruby_users.include?(user.id) }
        empty_likes_users = no_ruby_users.select do |user|
          user.like_music.nil?
        end
        other_users_likes = no_ruby_users.reject { |user| empty_likes_users.include?(user) }.map do |user|
          {
            id: user.id,
            likes: user.like_music
          }
        end
        empty_likes_users.each do |user|
          ruby_match << { 'other_user_id' => user.id, 'match_score' => 0 }
        end
        @user_count = other_users_likes.count

        content = "私の音楽性は「#{current_user_likes}」です。\n"
        content += "#{@user_count}人分の、他のユーザーのIDと音楽性を送ります。\n"
        content += "以下のルールに基づいて私とのマッチ度をIDと一緒に返してください。\n"
        content += "採点基準は相対評価で、音楽性（評価基準：文化的背景>音像的特徴>年代と地域）の近いアーティストを評価して採点してください。\n"
        content += "得点は1〜#{@user_count}の範囲で、一番音楽性が遠いユーザーは必ず1点、一番音楽性の近いのユーザーは必ず#{@user_count}点とし、必ず連番で並べてください。（同じ点数のユーザーは一人も作らないこと。）\n"
        content += '今回渡されたIDのユーザーにのみ採点を返してください。'
        content += "他のユーザーの音楽性:\n"
        other_users_likes.each do |user|
          content += "ユーザーID: #{user[:id]}, 音楽性: #{user[:likes]}\n"
        end
        Rails.logger.debug(content)
        content += '出力形式: [ { "other_user_id": user_id1, "match_score": match_score1}, { "other_user_id": user_id2, "match_score": match_score2}, ... ]'
        content += "出力形式以外の内容は何があっても返さないこと\n"
        begin
          client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
          response = client.chat(
            parameters: {
              model: 'gpt-4o-mini', # モデルを変更
              messages: [{ role: 'user', content: content }],
              temperature: 0
            }
          )
          ai_match = JSON.parse(response['choices'][0]['message']['content'].gsub(/```json|```/, '').strip)

          combined_match = ruby_match + ai_match
          combined_match.each do |match|
            match_record = Match.find_or_initialize_by(
              user_id: current_user.id,
              other_user_id: match['other_user_id']
            )
            match_record.score = match['match_score']
            if match_record.save
              match_record.touch
              flash.now[:success] = 'マッチ情報を更新しました。'
            end
          end
        rescue Faraday::TooManyRequestsError
          flash.now[:danger] = 'AI使用制限中'
        rescue JSON::ParserError
          flash.now[:danger] = 'AIが予期せぬ返答をしました。'
        rescue Faraday::ServerError
          flash.now[:danger] = '再試行してください。'
        end
      end
      @user_count = Match.where(user_id: current_user.id, score: 0..999).maximum(:score)
      @user = User.joins("LEFT JOIN matches ON matches.other_user_id = users.id AND matches.user_id = #{current_user.id}")
                  .select('users.*, matches.score as match_score')
                  .find(params[:id])
    end

    redirect_to profile_path if current_user == @user

    current_time = params[:time]
    set_meta_tags twitter: {
      title: '私を構成する9枚',
      card: 'summary_large_image',
      url: "https://metronote.jp/other_users/#{@user.id}?time=#{current_time}",
      image: "https://#{ENV['AWS_BUCKET_NAME']}.s3.us-east-1.amazonaws.com/album_grid_#{@user.id}_#{current_time}.png"
    }
    @user_albums = @user.user_albums.includes(:album)
  end
end
