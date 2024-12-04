class AddMentorIdToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :mentor_id, :integer
  end
end
