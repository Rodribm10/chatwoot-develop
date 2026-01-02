begin
  account = Account.first_or_create!(name: 'Chatwoot')

  # Ensure user is fresh or updated
  user = User.find_or_initialize_by(email: 'rodrigobm10@gmail.com')
  user.name = 'Rodrigo'
  user.password = 'Nicodemos10!'
  user.password_confirmation = 'Nicodemos10!'
  # user.role column does not exist, so we skip it. Access is defined by AccountUser.
  user.save!
  user.confirm

  AccountUser.find_or_create_by!(
    user_id: user.id,
    account_id: account.id,
    role: 'administrator'
  )
  puts 'SUCCESS_USER_CREATED_FINALLY'
rescue StandardError => e
  puts "ERROR: #{e.message}"
end
