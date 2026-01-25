email = 'rodrigobm10@gmail.com'
user = User.find_by(email: email)

if user
  puts "Current user type: #{user.type}"
  # Update to SuperAdmin
  # Using update_column to bypass validations if any, and direct SQL update is safer for type change sometimes
  user.update_column(:type, 'SuperAdmin')
  puts 'User promoted to SuperAdmin.'

  # Verify
  u_reload = User.find_by(email: email)
  puts "New type: #{u_reload.type}"
  puts "Is SuperAdmin class? #{u_reload.is_a?(SuperAdmin)}"
else
  puts 'User not found!'
end
