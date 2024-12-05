class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.integer :priority
      t.references :category, null: false, foreign_key: { to_table: :categories }
      t.references :parent_task, foreign_key: { to_table: :tasks }
      t.datetime :deadline
      t.datetime :start_date
      t.integer :status
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :assignee, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
