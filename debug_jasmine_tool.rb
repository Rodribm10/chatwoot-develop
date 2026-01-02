begin
  # Find an inbox that has Jasmine enabled or just any inbox
  inbox = Inbox.first
  account = inbox.account
  puts "Testing with Account: #{account.id}, Inbox: #{inbox.id}"
  
  key = 'status_suites'
  
  # Create a temporary config or ensure it exists
  config = Jasmine::ToolConfig.find_or_initialize_by(
    account: account, 
    inbox: inbox, 
    tool_key: key
  )
  config.is_enabled = true
  config.plug_play_id = '110'
  # Use a dummy token if not set, or keep existing.
  # If we set a token, it will be encrypted.
  config.plug_play_token = 'test_token' if config.plug_play_token.blank?
  config.save!

  puts "Config saved. ID: #{config.id}, Token present: #{config.plug_play_token.present?}"

  runner = Jasmine::ToolRunner.new(inbox, key)
  puts "Runner initialized. Running..."
  result = runner.run
  puts "Result: #{result.inspect}"
  
rescue => e
  puts "CRITICAL ERROR: #{e.class} - #{e.message}"
  puts e.backtrace.join("\n")
end
