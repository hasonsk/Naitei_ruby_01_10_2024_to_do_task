# Create Users
admin = User.create!(
  email: "admin@example.com",
  password: "password123",
  name: "Admin User",
  role: "supervisor"
)

user = User.create!(
  email: "user@example.com",
  password: "password123",
  name: "Regular User",
  role: "mentor"
)

# Create Categories
categories = [
  Category.create!(name: "Development", user_id: admin.id),
  Category.create!(name: "Design", user_id: user.id),
  Category.create!(name: "Management", user_id: admin.id)
]

# Create Tasks
tasks = []
10.times do |i|
  task = Task.create!(
    title: "Task #{i + 1}",
    description: "This is a detailed description for Task #{i + 1}.",
    priority: %w[low medium high urgent].sample,
    category: categories.sample,
    parent_task_id: i.even? ? nil : tasks.sample&.id,
    deadline: rand(5..15).days.from_now,
    start_date: rand(1..5).days.ago,
    status: %w[pending in_progress completed expired].sample,
    created_at: Time.now,
    updated_at: Time.now
  )

  task.task_participants.create!(user: admin, role: "creator")
  task.task_participants.create!(user: user, role: "assignee") if [ true, false ].sample

  tasks << task
end

puts "Seed data created successfully!"


# Users
user_1 = User.find(1)
user_2 = User.find(2)

# Tasks (Giả sử đã có sẵn một số tasks trong database)
tasks = Task.all

if tasks.any?
  puts "Seeding comments for users..."

  tasks.each do |task|
    # Seed comments từ user_1
    Comment.create!(
      content: "This is a comment by #{user_1.name} on Task ##{task.id}.",
      task_id: task.id,
      user_id: user_1.id
    )

    # Seed comments từ user_2
    Comment.create!(
      content: "This is another comment by #{user_2.name} on Task ##{task.id}.",
      task_id: task.id,
      user_id: user_2.id
    )
  end

  puts "Comments seeded successfully!"
else
  puts "No tasks available to seed comments."
end
