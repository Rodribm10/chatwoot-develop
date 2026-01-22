class DebugToken
  def self.run
    email = 'rodrigobm10@gmail.com' # Use the email from the context
    user = User.find_by(email: email)

    unless user
      puts 'User not found!'
      return
    end

    puts 'Generating reset password instructions...'
    raw_token = user.send_reset_password_instructions
    puts "Raw Token generated: #{raw_token}"

    # Reload user to get the saved digest
    user.reload
    puts "Saved reset_password_token digest: #{user.reset_password_token}"
    puts "Saved reset_password_sent_at: #{user.reset_password_sent_at}"

    # Simulate Controller Logic
    # DeviseOverrides::PasswordsController#update logic

    # 1. Digest the raw token
    digested_token = Devise.token_generator.digest(DeviseOverrides::PasswordsController, :reset_password_token, raw_token)
    puts "Digested Token (using Controller class): #{digested_token}"

    # 2. Find user
    found_user = User.find_by(reset_password_token: digested_token)

    if found_user
      puts 'SUCCESS: User found using controller logic.'
      if found_user.id == user.id
        puts 'User ID matches.'
      else
        puts 'User ID mismatch!'
      end
    else
      puts 'FAILURE: User NOT found using controller logic.'

      # Try digesting with User class just in case of scope difference (unlikely for Devise default)
      digested_token_user_scope = Devise.token_generator.digest(User, :reset_password_token, raw_token)
      puts "Digested Token (using User class): #{digested_token_user_scope}"

      if digested_token == digested_token_user_scope
        puts 'Digests match between Controller and User scope.'
      else
        puts 'Digests DO NOT match. This might be the issue if Devise mapping is wrong.'
      end
    end
  end
end

DebugToken.run
