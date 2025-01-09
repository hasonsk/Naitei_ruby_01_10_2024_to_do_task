class ActivityLogger
  def self.log(user: @user, task:, action:, description: nil, changes: {})
    activity_description = description || generate_description(action, changes)
    Activity.create!(
      user: user,
      task: task,
      action: action,
      description: activity_description
    )
  end

  private

  def self.generate_description(action, changes)
    case action
    when "updated"
      changes.map do |field, (old_value, new_value)|
        "#{field.capitalize}: '#{old_value}' -> '#{new_value}'"
      end.join(", ")
    end
  end
end
