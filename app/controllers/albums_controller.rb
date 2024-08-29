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
    rescue JSON::ParserError => e
      flash.now[:danger] = "再試行してください。"
    end

    begin
      album_record = Album.find_or_create_by(
        artist_name: album_details['artistName'],
        album_name: album_details['collectionName'],
        itunes_album_id: album_details['collectionId'],
        artwork_url: album_details['artworkUrl100']
      )
    rescue NoMethodError => e
      flash.now[:danger] = "再試行してください。"
      return
    end

    album_param = session[:album_search]

    if current_user.user_albums.count >= 9
      flash[:danger] = "アルバムの追加は9枚までです。"
      redirect_to albums_path(album: album_param)
    elsif current_user.user_albums.exists?(album_id: album_record.id)
      flash[:danger] = "同じアルバムは追加できません。"
      redirect_to albums_path(album: album_param)
    else
      @user_album = current_user.user_albums.new(album: album_record)
      if @user_album.save
        current_user.update(like_music: current_user.user_albums.map { |ua| "#{ua.album.artist_name}の#{ua.album.album_name} (ID: #{ua.album.id})" }.join(", "))
        redirect_to albums_path(album: album_param), success: "アルバムを保存しました。"
      else
        flash[:danger] = "アルバムの保存に失敗しました。"
        redirect_to albums_path(album: album_param)
      end
    end
  end

  def share
    @user_albums = current_user.user_albums.includes(:album).order(created_at: :asc).limit(9)
  
    require 'open-uri'
    require 'stringio'
    # 画像全体のサイズ
    grid_size = 418  # グリッド全体のサイズ
    cell_size = grid_size / 3  # 各セルのサイズ
  
    background_path = Rails.root.join('public', 'metro-sea.png')
    canvas = MiniMagick::Image.open(background_path)
    # 各アルバムアートワークをグリッドに配置
    @user_albums.each_with_index do |user_album, index|
      artwork_url = user_album.album.artwork_url
      puts artwork_url
      URI.open(artwork_url) do |image|
        artwork = MiniMagick::Image.read(image.read)
        if artwork.height > artwork.width
          artwork.resize "#{cell_size}x" # 高さに合わせてリサイズ
        elsif artwork.height < artwork.width
          artwork.resize "x#{cell_size}" # 幅に合わせてリサイズ
        else
          artwork.resize "#{cell_size}x#{cell_size}"
        end
  
        resized_width = artwork.width
        resized_height = artwork.height
        # グリッド上の位置を計算
        x_position = (index % 3) * cell_size + (cell_size - resized_width) / 2 + 191 # 余白を考慮して位置を調整
        y_position = (index / 3) * cell_size + (cell_size - resized_height) / 2
  
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
    object_key = "album_grid_#{current_user.id}.png"

    # 既存のオブジェクトを削除
    s3_bucket.object(object_key).delete if s3_bucket.object(object_key).exists?

    # メモリの内容をS3にアップロード
    output.rewind # StringIOのポインタを先頭に戻す
    s3_bucket.object(object_key).put(body: output.read)
  
    # Twitterシェア用のURL生成
    current_time = Time.now.strftime("%Y%m%d%H%M%S")
    app_url = "https://metronote.jp/other_users/#{current_user.id}?#{current_time}"
    x_url = "https://x.com/intent/tweet?url=#{CGI.escape(app_url)}"
  
    redirect_to x_url, allow_other_host: true
  end

  def destroy
    album_param = session[:album_search]
    user_album = current_user.user_albums.find_by(album_id: params[:id])
    user_album.destroy
    current_user.update(like_music: current_user.user_albums.map { |ua| "#{ua.album.artist_name}の#{ua.album.album_name} (ID: #{ua.album.id})" }.join(", "))
    flash[:danger] = "アルバムを削除しました。"
    redirect_to albums_path(album: album_param)
  end
end