class Task < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :parent_task, class_name: "Task", optional: true
  has_many :subtasks, class_name: "Task", foreign_key: :parent_task_id, dependent: :destroy
  has_many :task_participants, dependent: :destroy
  has_many :participants, through: :task_participants, source: :user
  has_many :comments, dependent: :destroy
  has_many :activities, dependent: :destroy

  accepts_nested_attributes_for :task_participants, allow_destroy: true

  enum priority: Settings.default.priorities.to_h.transform_keys(&:to_sym)
  enum status: Settings.default.status.to_h.transform_keys(&:to_sym)

  validates :title, presence: true, length: { maximum: Settings.default.task_title_max_length }
  validates :priority, presence: true
  validates :status, presence: true
  validates :deadline, comparison: { greater_than: :start_date, allow_blank: true }, if: :start_date?
  TASK_PERMITTED_ATTRIBUTES = %i[title description priority status start_date deadline category_id user_id assignee_id parent_task_id].freeze
  SUBTASK_PERMITTED_ATTRIBUTES = %i[title description priority status assignee_id start_date deadline category_id].freeze
  scope :by_naitei, ->(user_id) { where("user_id = :user_id OR assignee_id = :user_id", user_id: user_id) }
  scope :by_priority, ->(priority) { where(priority: priorities[priority]) }
  scope :by_status, ->(status) { where(status: statuses[status]) }
  scope :filter_by_category, ->(category) { where(category_id: category) if category.present? }
  scope :filter_by_status, ->(status) { where(status: status) if status.present? }
  scope :filter_by_deadline, ->(deadline) { where("deadline <= ?", deadline) if deadline.present? }
end
