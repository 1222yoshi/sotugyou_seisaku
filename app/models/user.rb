class User < ApplicationRecord
  before_save :normalize_links
  authenticates_with_sorcery!
  mount_uploader :profile_image, ProfileImageUploader

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: true
  validates :reset_password_token, uniqueness: true, allow_nil: true
  validates :reset_email_token, uniqueness: true, allow_nil: true

  has_many :user_areas, dependent: :destroy
  has_many :areas, through: :user_areas
  has_many :user_instruments, dependent: :destroy
  has_many :instruments, through: :user_instruments
  has_many :user_albums, -> { order(order_number: :asc) }, dependent: :destroy
  has_many :albums, through: :user_albums
  has_many :matches
  has_many :other_users, through: :matches, source: :other_user
  has_many :likes, foreign_key: :like_user_id
  has_many :liked_users, through: :likes, source: :liked_user
  has_many :chatrooms_as_user_1, class_name: 'Chatroom', foreign_key: 'user_1_id'
  has_many :chatrooms_as_user_2, class_name: 'Chatroom', foreign_key: 'user_2_id'
  has_many :messages
  has_many :user_quizzes
  has_many :results

  def age
    if birthdate.present?
      today = Date.today
      age = today.year - birthdate.year
      age -= 1 if today < birthdate + age.years
      "#{age}歳"
    else
      '年齢非公開'
    end
  end

  def gender_japanese
    case gender
    when 'male'
      '男性'
    when 'female'
      '女性'
    else
      '性別非公開'
    end
  end

  # 目的を日本語に変換するメソッド
  def purpose_japanese
    case purpose
    when 'pro'
      'プロ志望'
    when 'hobby'
      '趣味'
    else
      '目的未設定'
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name purpose] # ここで検索可能な属性を指定
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[areas user_areas instruments user_instruments] # ここで検索可能なアソシエーションを指定
  end

  def generate_reset_email_token!
    self.reset_email_token = SecureRandom.urlsafe_base64
    self.reset_email_token_expires_at = 1.hour.from_now # トークン有効期限
    self.reset_email_sent_at = Time.current
    save!
  end

  def reset_email_token_valid?
    if reset_email_token_expires_at && reset_email_token_expires_at > Time.current
      true
    else
      update(reset_email: nil, reset_email_token: nil, reset_email_token_expires_at: nil)
      false
    end
  end

  attr_accessor :i_like
  attr_accessor :i_liked
  attr_accessor :notification_now
  attr_accessor :sorted_albums

  private

  def normalize_links
    normalize_x_link
    normalize_instagram_link
    normalize_youtube_link
    normalize_custom_link
  end

  def normalize_x_link
    return unless x_link.present?

    # "@"を追加し、URL形式を統一
    normalized_link = x_link.gsub(%r{(https?://)?(x\.com/)?@?}, '')
    normalized_link = normalized_link.split('/').first
    self.x_link = "@#{normalized_link}"
  end

  def normalize_instagram_link
    return unless instagram_link.present?

    normalized_link = instagram_link.gsub(%r{(https?://)?(www\.instagram\.com/)?@?}, '')
    normalized_link = normalized_link.split('/').first
    self.instagram_link = "@#{normalized_link}"
  end

  def normalize_youtube_link
    return unless youtube_link.present?

    normalized_link = youtube_link.gsub(%r{(https?://)?(www\.youtube\.com/)?@?}, '')
    normalized_link = normalized_link.split('/').first
    self.youtube_link = "@#{normalized_link}"
  end

  def normalize_custom_link
    return unless custom_link.present?

    # https://の部分を取り除く
    self.custom_link = custom_link.gsub(%r{https?://}, '')
  end
end
