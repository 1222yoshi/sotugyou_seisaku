class AlbumsController < ApplicationController
  skip_before_action :require_login, only: %i[index show]
  def index
    if current_user
      @user_albums = current_user.user_albums.includes(:album).order(created_at: :asc)
    end

    if params[:artist].present? || params[:album].present? || params[:track].present?
      search_term = "#{params[:artist]} #{params[:album]} #{params[:track]}"
      begin
        albums = ITunesSearchAPI.search(term: search_term, media: 'music', entity: 'album', country: 'jp')
        tracks = ITunesSearchAPI.search(term: search_term, media: 'music', entity: 'musicTrack', country: 'jp')
        @albums = (albums + tracks).select { |result| result['collectionId'].present? }.uniq { |result| result['collectionId'] }
      rescue JSON::ParserError => e
        @albums = []
        flash.now[:danger] = "再試行してください。"
      end
    else
      @albums = []
    end

    session[:album_search] = params[:album]
  end
  
  def show
    begin
      @album = ITunesSearchAPI.lookup(id: params[:id], media: 'music', entity: 'album', country: 'jp')
    rescue SocketError => e
      flash.now[:danger] = "再試行してください。"
    end

    if current_user
      @user_album = current_user.user_albums.joins(:album).find_by(albums: { itunes_album_id: params[:id] })        
    end                     

    choosed_album = Album.find_by(itunes_album_id: params[:id])
    
    if choosed_album
      if current_user
        @album_users = User.joins(:user_albums)
                           .where(user_albums: { album_id: choosed_album.id })
                           .where.not(id: current_user.id)
      else
        @album_users = User.joins(:user_albums)
                           .where(user_albums: { album_id: choosed_album.id })    
      end
    else
      @album_users = []
    end
  end

  def choose
    begin
      album_details = ITunesSearchAPI.lookup(id: params[:id], media: 'music', entity: 'album', country: 'jp')
  
      album_record = Album.find_or_create_by(
        artist_name: album_details['artistName'],
        album_name: album_details['collectionName'],
        itunes_album_id: album_details['collectionId'],
        artwork_url: album_details['artworkUrl100']
      )

      album_param = session[:album_search]

      if current_user.user_albums.count >= 9
        flash[:danger] = "アルバムの追加は9枚までです。"
        redirect_to albums_path(album: album_param)
      elsif current_user.user_albums.exists?(album_id: album_record.id)
        flash[:danger] = "同じアルバムは追加できません。"
        redirect_to albums_path(album: album_param)
      else
        @user_album = current_user.user_albums.new(album: album_record)
        if current_user.user_albums.count == 8 
          like_artist_names = current_user.user_albums.includes(:album).map(&:album).map(&:artist_name).uniq.reject { |artist_name| artist_name == 'Various Artists' }
          content = "gptの持つ全ての音楽の情報を使って処理してください。\n"
          content += "私は「#{like_artist_names}」というアーティストたちが好きです。\n"
          content += "与えられたアーティストのリストから、音楽の特徴やスタイルを分析し、ユーザーが好む音楽の傾向を要約して作成してください。具体的には、以下のポイントに注目して解析してほしいです。\n"
          content += "1.文化的特徴 2.楽器的特徴 3.コード、リズム的特徴 4.歌詞的特徴\n"
          content += "これらの情報は、各ユーザーとの比較にそのまま使われます。よってあなたが読み取りやすい程度に要約して返してください。\n"
          content += "出力形式は3つのポイントをそれぞれ50文字程度で端的に文章で送ってください。音楽的情報以外の発言はしないでください。"
          begin
            client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
            response = client.chat(
              parameters: {
                model: "gpt-4o-mini", # モデルを変更
                messages: [{ role: "user", content: content }],
                temperature: 0
              }
            )

            user_music_text = response["choices"][0]["message"]["content"]
            Rails.logger.debug(response)
            current_user.update(like_music: user_music_text)
            if @user_album.save
              redirect_to albums_path, success: "アルバムを保存しました。"
              return
            else
              flash[:danger] = "アルバムの保存に失敗しました。"
              redirect_to albums_path(album: album_param)
              return
            end
          rescue Faraday::TooManyRequestsError => e
            flash.now[:danger] = "AI使用制限中"
          rescue JSON::ParserError => each
            flash.now[:danger] = "AIが予期せぬ返答をしました。"
          rescue Faraday::ServerError => e
            flash.now[:danger] = "再試行してください。"  
          end
          head :no_content
        else      
          if @user_album.save
            redirect_to albums_path(album: album_param), success: "アルバムを保存しました。"
          else
            flash[:danger] = "アルバムの保存に失敗しました。"
            redirect_to albums_path(album: album_param)
          end
        end
      end

    rescue JSON::ParserError, NoMethodError, StandardError => e
      flash.now[:danger] = "再試行してください。"
      redirect_to albums_path(album: album_param)
    end
  end

  def share
    @user_albums = current_user.user_albums.includes(:album).order(created_at: :asc).limit(9)
  
    current_time = Time.now.strftime("%Y%m%d%H%M%S")

    require 'open-uri'
    require 'stringio'
    # 画像全体のサイズ
    grid_size = 372  # グリッド全体のサイズ
    cell_size = grid_size / 3  # 各セルのサイズ
  
    background_path = Rails.root.join('public', 'metro-logo.png')
    canvas = MiniMagick::Image.open(background_path)
    # 各アルバムアートワークをグリッドに配置
    @user_albums.each_with_index do |user_album, index|
      artwork_url = user_album.album.artwork_url
      puts artwork_url
      URI.open(artwork_url) do |image|
        artwork = MiniMagick::Image.read(image.read)
        if artwork.height > artwork.width
          artwork.resize "#{cell_size}x" # 高さに合わせてリサイズ
          artwork.crop "#{cell_size}x#{cell_size}+0+#{(artwork.height - cell_size) / 2}"
        elsif artwork.height < artwork.width
          artwork.resize "x#{cell_size}" # 幅に合わせてリサイズ
          artwork.crop "#{cell_size}x#{cell_size}+#{(artwork.width - cell_size) / 2}+0"
        else
          artwork.resize "#{cell_size}x#{cell_size}"
        end
  
        resized_width = artwork.width
        resized_height = artwork.height
        # グリッド上の位置を計算
        x_position = (index % 3) * cell_size + (cell_size - resized_width) / 2 + 414 # 余白を考慮して位置を調整
        y_position = (index / 3) * cell_size + (cell_size - resized_height) / 2 + 128
  
        # アートワークをキャンバスに合成
        canvas = canvas.composite(artwork) do |c|
          c.geometry "+#{x_position}+#{y_position}"
        end
      end
    end
  
    # メモリ上に画像を書き込む
    output = StringIO.new
    canvas.write(output)

    # S3に画像をアップロード
    s3 = Aws::S3::Resource.new(region: 'us-east-1')
    s3_bucket = s3.bucket(ENV['AWS_BUCKET_NAME']) # バケット名を指定
    object_key = "album_grid_#{current_user.id}_#{current_time}.png"

    s3_bucket.objects(prefix: "album_grid_#{current_user.id}").each do |obj|
      if obj.key.start_with?("album_grid_#{current_user.id}") 
        obj.delete
      end
    end

    # メモリの内容をS3にアップロード
    output.rewind # StringIOのポインタを先頭に戻す
    s3_bucket.object(object_key).put(body: output.read)
  
    # Twitterシェア用のURL生成
    app_url = "https://metronote.jp/other_users/#{current_user.id}?time=#{current_time}"
    default_text = "#私を構成する9枚"
    x_url = "https://x.com/intent/tweet?url=#{CGI.escape(app_url)}&text=#{CGI.escape(default_text)}"
  
    redirect_to x_url, allow_other_host: true
  end

  def destroy
    album_param = session[:album_search]
    user_album = current_user.user_albums.find_by(album_id: params[:id])
    user_album.destroy
    flash[:danger] = "アルバムを削除しました。"
    current_user.update(like_music: nil)
    redirect_to albums_path(album: album_param)
  end
end