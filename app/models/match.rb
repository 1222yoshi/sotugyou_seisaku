class Match < ApplicationRecord
  belongs_to :user
  belongs_to :other_user, class_name: 'User'

  validates :user_id, presence: true
  validates :other_user_id, presence: true
  validates :score, presence: true
end
