# frozen_string_literal: true

puts "Seeding TeamHub demo data..."

alice = User.find_or_initialize_by(email: "alice@example.com")
alice.name = "Alice"
alice.password = "password123"
alice.password_confirmation = "password123"
alice.save!

bob = User.find_or_initialize_by(email: "bob@example.com")
bob.name = "Bob"
bob.password = "password123"
bob.password_confirmation = "password123"
bob.save!

org = Organization.find_or_create_by!(name: "TeamHub Org")
Membership.find_or_create_by!(organization: org, user: alice) { |m| m.role = :owner }
Membership.find_or_create_by!(organization: org, user: bob) { |m| m.role = :member }

project = Project.find_or_create_by!(organization: org, name: "Platform") do |p|
  p.description = "Main sample project"
  p.status = :active
end

task = Task.find_or_create_by!(project: project, title: "Initial setup") do |t|
  t.description = "Verify login, project management, and notifications"
  t.assignee = bob
  t.status = :in_progress
  t.priority = :high
  t.due_on = Date.current + 3.days
  t.content = "Seeded **rich text** content."
end

Announcement.find_or_create_by!(project: project, user: alice, title: "Welcome") do |a|
  a.body = "Welcome to TeamHub sample app"
  a.published_at = Time.current
end

Notification.find_or_create_by!(user: bob, kind: :generic, payload: { message: "Seed notification" }.to_json)

puts "Done."
puts "Sign in as alice@example.com / password123 or bob@example.com / password123"
