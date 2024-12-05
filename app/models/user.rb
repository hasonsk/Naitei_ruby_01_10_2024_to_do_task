class User < ApplicationRecord
  has_secure_password

  has_many :created_tasks, class_name: "Task", foreign_key: :creator_id, dependent: :destroy
  has_many :assigned_tasks, class_name: "Task", foreign_key: :assignee_id, dependent: :nullify
  has_many :categories, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :task_participants, dependent: :destroy
  has_many :participated_tasks, through: :task_participants, source: :task

  enum role: Settings.default.roles.symbolize_keys

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { maximum: Settings.default.username_max_length_100 }
  validates :role, presence: true
end
