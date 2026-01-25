# Seed Captain Tool Configs for Inbox 14 AND 15

[14, 15].each do |inbox_id|
  inbox = Inbox.find_by(id: inbox_id)

  unless inbox
    puts "Inbox #{inbox_id} not found! Skipping..."
    next
  end

  account = inbox.account

  puts "Seeding tools for Inbox: #{inbox.name} (ID: #{inbox.id}, Account: #{account.id})..."

  configs = [
    {
      tool_key: 'status_suites',
      is_enabled: true,
      plug_play_id: 'TEST_PP_ID_123',
      plug_play_token: 'TEST_PP_TOKEN_456',
      webhook_url: nil
    },
    {
      tool_key: 'maria_fotos',
      is_enabled: true,
      webhook_url: 'https://mock.webhook.site/photos'
    },
    {
      tool_key: 'escalar_humano',
      is_enabled: true,
      webhook_url: 'https://mock.webhook.site/escalate'
    }
  ]

  configs.each do |config|
    tool_config = CaptainToolConfig.find_or_initialize_by(
      account: account,
      inbox: inbox,
      tool_key: config[:tool_key]
    )

    tool_config.assign_attributes(config)

    if tool_config.save
      puts "✅ Configured #{config[:tool_key]}"
    else
      puts "❌ Failed #{config[:tool_key]}: #{tool_config.errors.full_messages}"
    end
  end
end

puts 'Seed complete for all Inboxes!'
