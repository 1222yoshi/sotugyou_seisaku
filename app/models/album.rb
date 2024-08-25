class Album < ApplicationRecord
  has_many :user_albums, dependent: :destroy
  has_many :users, through: :user_albums
end
