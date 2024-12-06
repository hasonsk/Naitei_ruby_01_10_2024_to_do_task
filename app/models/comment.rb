class Comment < ApplicationRecord
  belongs_to :task
  belongs_to :user

  validates :content, presence: true, length: { maximum: Settings.default.comment_max_length_10_000 }
end
