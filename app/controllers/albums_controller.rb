class AlbumsController < ApplicationController
  skip_before_action :require_login, only: %i[index show]
  def index
    if current_user
      @user_albums = current_user.user_albums.includes(:album).order(created_at: :asc)
    end

    if params[:artist].present? || params[:album].present? || params[:track].present?
      search_term = "#{params[:artist]} #{params[:album]} #{params[:track]}"
      albums = ITunesSearchAPI.search(term: search_term, media: 'music', entity: 'album', country: 'jp')
      tracks = ITunesSearchAPI.search(term: search_term, media: 'music', entity: 'musicTrack', country: 'jp')
      @albums = (albums + tracks).select { |result| result['collectionId'].present? }.uniq { |result| result['collectionId'] }
    else
      @albums = []
    end

    session[:album_search] = params[:album]
  end
  
  def show
    @album = ITunesSearchAPI.lookup(id: params[:id], media: 'music', entity: 'album', country: 'jp')

    if current_user
      @user_album = current_user.user_albums.joins(:album).find_by(albums: { itunes_album_id: params[:id] })
    end
  end

  def choose
    album_details = ITunesSearchAPI.lookup(id: params[:id], media: 'music', entity: 'album', country: 'jp')
    if album_details.nil?
      flash[:error] = "アルバムの詳細情報を取得できませんでした。"
      redirect_back(fallback_location: root_path)
      return
    end

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
      if @user_album.save
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
    # 画像全体のサイズ
    grid_size = 418  # グリッド全体のサイズ
    cell_size = grid_size / 3  # 各セルのサイズ
  
    background_path = Rails.root.join('public', 'background.png')
    canvas = MiniMagick::Image.open(background_path)
    # 各アルバムアートワークをグリッドに配置
    @user_albums.each_with_index do |user_album, index|
      artwork_url = user_album.album.artwork_url
      puts artwork_url
      URI.open(artwork_url) do |image|
        artwork = MiniMagick::Image.read(image.read)
        artwork.resize "#{cell_size}x#{cell_size}"
  
        # グリッド上の位置を計算
        x_position = (index % 3) * cell_size + 191 # 余白を考慮して位置を調整
        y_position = (index / 3) * cell_size 
  
        # アートワークをキャンバスに合成
        canvas = canvas.composite(artwork) do |c|
          c.geometry "+#{x_position}+#{y_position}"
        end
      end
    end
  
    # 一時的に画像を保存
    public_file = Rails.root.join('public', "album_grid_#{current_user.id}.png")
    File.delete(public_file) if File.exist?(public_file)
    canvas.write(public_file)
  
    # Twitterシェア用のURL生成
    current_time = Time.now.strftime("%Y%m%d%H%M%S")
    app_url = "https://metronote-a37794a02853.herokuapp.com/other_users/#{current_user.id}?#{current_time}"
    x_url = "https://x.com/intent/tweet?url=#{CGI.escape(app_url)}"
  
    redirect_to x_url, allow_other_host: true
  end

  def destroy
    album_param = session[:album_search]
    user_album = current_user.user_albums.find_by(album_id: params[:id])
    user_album.destroy
    flash[:danger] = "アルバムを削除しました。"
    redirect_to albums_path(album: album_param)
  end
end