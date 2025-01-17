class UserAlbum < ApplicationRecord
  belongs_to :user
  belongs_to :album
  default_scope { order(order_number: :asc) }
end
