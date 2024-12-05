class CreateTaskParticipants < ActiveRecord::Migration[7.2]
  def change
    create_table :task_participants do |t|
      t.references :task, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role

      t.timestamps
    end
  end
end
