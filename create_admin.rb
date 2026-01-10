# Ensure pricing plan allows user creation
installation_config = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
installation_config.value = 100
installation_config.save!

# Create or update account
account = Account.first || Account.create!(name: 'Acme Inc')

# Create or find user
user = User.find_or_initialize_by(email: 'rodrigobm10@gmail.com')
user.name = 'Rodrigo'
user.password = 'Password123!'
user.password_confirmation = 'Password123!'
user.confirmed_at = Time.current
user.save!

# Link user to account as admin
AccountUser.find_or_create_by!(account: account, user: user, role: :administrator)

puts "User #{user.email} created/updated successfully."
