class User < ApplicationRecord
  authenticates_with_sorcery!
  mount_uploader :profile_image, ProfileImageUploader

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  validates :name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, uniqueness: true

  GENDER_OPTIONS = {
    "男性" => "male",
    "女性" => "female",
    "その他" => "other"
  }.freeze
end
