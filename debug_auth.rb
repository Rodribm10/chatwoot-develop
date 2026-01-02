email = 'rodrigobm10@gmail.com'
password = 'Password123!'

puts '=== DEBUGGING AUTH ==='
user = User.find_by(email: email)
puts 'User found via find_by: ' + (user ? 'YES' : 'NO')

if user
  puts 'User ID: ' + user.id.to_s
  puts 'User Email: ' + user.email

  puts 'Checking User.from_email...'
  begin
    user_from_method = User.from_email(email)
    puts 'User found via User.from_email: ' + (user_from_method ? 'YES' : 'NO')
  rescue => e
    puts 'Error in User.from_email: ' + e.message
  end
  
  puts 'Checking valid_password?...'
  is_valid = user.valid_password?(password)
  puts 'Password valid: ' + is_valid.to_s
  
  puts 'Checking active_for_authentication?...'
  is_active = user.active_for_authentication?
  puts 'Active for auth: ' + is_active.to_s
  
  if !is_active
    puts 'User inactive message: ' + user.inactive_message.to_s
  end
else
  puts 'User not found!'
end
puts '=== END DEBUG ==='
