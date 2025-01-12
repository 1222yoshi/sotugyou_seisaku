class Like < ApplicationRecord
  belongs_to :like_user, class_name: 'User'
  belongs_to :liked_user, class_name: 'User'
end
