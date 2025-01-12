class Quiz < ApplicationRecord
  has_many :choices

  def rank_letter
    case quiz_rank
    when 5
      'S'
    when 4
      'A'
    when 3
      'B'
    when 2
      'C'
    when 1
      'D'
    end
  end

  def rank_class
    case quiz_rank
    when 5
      's'
    when 4
      'a'
    when 3
      'b'
    when 2
      'c'
    when 1
      'd'
    end
  end
end
