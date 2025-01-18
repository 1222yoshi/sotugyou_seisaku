class UserAlbum < ApplicationRecord
  belongs_to :user
  belongs_to :album
end
