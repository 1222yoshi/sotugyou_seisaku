class AlbumsController < ApplicationController
  def index
    @user_albums = current_user.user_albums.includes(:album).order(created_at: :asc)

    if params[:artist].present? || params[:album].present? || params[:track].present?
      search_term = "#{params[:artist]} #{params[:album]} #{params[:track]}"
      albums = ITunesSearchApi.search(term: search_term, media: 'music', entity: 'album', country: 'jp')
      tracks = ITunesSearchApi.search(term: search_term, media: 'music', entity: 'musicTrack', country: 'jp')
      @albums = (albums + tracks).select { |result| result['collectionId'].present? }.uniq { |result| result['collectionId'] }
    else
      @albums = []
    end

    session[:album_search] = params[:album]
  end
  
  def show
    @album = ITunesSearchApi.lookup(id: params[:id], media: 'music', entity: 'album', country: 'jp')

    @user_album = current_user.user_albums.joins(:album).find_by(albums: { itunes_album_id: params[:id] })
  end

  def choose
    album_details = ITunesSearchApi.lookup(id: params[:id], media: 'music', entity: 'album', country: 'jp')
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
  
    # 画像全体のサイズ
    grid_size = 300  # グリッド全体のサイズ
    cell_size = grid_size / 3  # 各セルのサイズ
  
    canvas_path = Rails.root.join('tmp', "canvas_#{current_user.id}.png")

  
    # 画像を読み込み
    canvas = MiniMagick::Image.open(canvas_path)
  
    # 各アルバムアートワークをグリッドに配置
    @user_albums.each_with_index do |user_album, index|
      artwork = MiniMagick::Image.open(user_album.album.artwork_url)
      artwork.resize "#{cell_size}x#{cell_size}"
  
      # グリッド上の位置を計算
      x_position = (index % 3) * cell_size + 50 # 余白を考慮して位置を調整
      y_position = (index / 3) * cell_size + 50
  
      # アートワークをキャンバスに合成
      canvas = canvas.composite(artwork) do |c|
        c.geometry "+#{x_position}+#{y_position}"
      end
    end
  
    # テキスト "MeTRO NOTE" を追加
    canvas.combine_options do |c|
      c.gravity 'southeast' # 右下に配置
      c.fill "#8bd3ff" # テキストの色を設定
      c.font Rails.root.join('app/assets/fonts/shin-retro-maru-gothic.ttf').to_s # カスタムフォントのパス
      c.pointsize 20 # フォントサイズを設定
      c.draw "text 10,10 'MeTRO NOTE'" # テキストの描画位置を設定
      c.annotate "+10+10", "text 0,0 'MeTRO NOTE'"
      c.draw "text 0,0 'MeTRO NOTE'"
      c.draw "text 1,1 'MeTRO NOTE'"
      c.shadow "50x4+0+0"
    end
  
    # 一時的に画像を保存
    public_file = Rails.root.join('public', "album_grid_#{current_user.id}.png")
    canvas.write(public_file)

    image_url = url_for("/album_grid_#{current_user.id}.png")
  
    # Twitterシェア用のURL生成
    app_url = "https://metronote-a37794a02853.herokuapp.com/"
    twitter_url = "https://twitter.com/intent/tweet?text=#{CGI.escape('Check out my albums!')}&url=#{CGI.escape(app_url)}&via=#{CGI.escape(current_user.x_link)}"
  
    redirect_to twitter_url, allow_other_host: true
  end

  def destroy
    album_param = session[:album_search]
    user_album = current_user.user_albums.find_by(album_id: params[:id])
    user_album.destroy
    flash[:danger] = "アルバムを削除しました。"
    redirect_to albums_path(album: album_param)
  end
end