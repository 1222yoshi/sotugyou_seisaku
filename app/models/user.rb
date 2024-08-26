class User < ApplicationRecord
  authenticates_with_sorcery!
  mount_uploader :profile_image, ProfileImageUploader

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: true

  has_many :user_areas, dependent: :destroy
  has_many :areas, through: :user_areas
  has_many :user_instruments, dependent: :destroy
  has_many :instruments, through: :user_instruments
  has_many :user_albums, dependent: :destroy
  has_many :albums, through: :user_albums
  has_many :matches
  has_many :other_users, through: :matches, source: :other_user
  
  def age
    return unless birthdate.present?
    today = Date.today
    age = today.year - birthdate.year
    age -= 1 if today < birthdate + age.years
    age
  end

  def gender_japanese
    case gender
    when 'male'
      '男性'
    when 'female'
      '女性'
    else
      '未設定'
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
      '未設定'
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["name"] # ここで検索可能な属性を指定
  end
end
