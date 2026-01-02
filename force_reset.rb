email = 'rodrigobm10@gmail.com'
password = 'Password123!'

puts '=== FORCING PASSWORD RESET ==='
u = User.find_by(email: email)
if u
  u.password = password
  u.password_confirmation = password
  if u.save
    puts 'User saved successfully.'
  else
    puts 'Error saving user: ' + u.errors.full_messages.join(', ')
  end
  
  # Reload and verify
  u.reload
  puts 'Password check immediately after save: ' + u.valid_password?(password).to_s
else
  puts 'User NOT FOUND to reset password.'
end
puts '=== END RESET ==='
