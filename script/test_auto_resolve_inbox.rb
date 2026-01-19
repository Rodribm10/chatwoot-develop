# script/test_auto_resolve_inbox.rb
require 'logger'

# Setup logger
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

logger.info '--- Testing Auto-Resolve by Inbox Logic ---'

ActiveRecord::Base.transaction do
  # 1. Setup Data
  account = Account.create!(name: 'Test Account AutoResolve')

  # Inbox WITH specific auto_resolve_duration (e.g., 2 minutes)
  inbox_specific = Inbox.create!(
    name: "Inbox Specific #{Time.now.to_i}",
    account: account,
    channel: Channel::Api.create!(account: account),
    auto_resolve_duration: 2
  )

  # Inbox WITHOUT specific auto_resolve_duration (should use account default)
  inbox_default = Inbox.create!(
    name: "Inbox Default #{Time.now.to_i}",
    account: account,
    channel: Channel::Api.create!(account: account),
    auto_resolve_duration: nil
  )

  # Configure Account Default to 10 minutes
  account.update!(auto_resolve_duration: nil)
  account.settings['auto_resolve_after'] = 10
  account.save!

  logger.info "Account auto_resolve_after: #{account.auto_resolve_after}"
  logger.info "Inbox Specific duration: #{inbox_specific.auto_resolve_duration}"
  logger.info "Inbox Default duration: #{inbox_default.auto_resolve_duration}"

  # Setup Contact and ContactInbox
  contact = Contact.create!(account: account, name: 'Test Contact', email: 'test@example.com', phone_number: '+1234567890')

  # Create ContactInbox with source_id (required)
  ContactInbox.create!(contact: contact, inbox: inbox_specific, source_id: "source_spec_#{Time.now.to_i}")
  ContactInbox.create!(contact: contact, inbox: inbox_default, source_id: "source_default_#{Time.now.to_i}")

  # 2. Create Conversations

  # Case A: Inbox Specific - Old enough to resolve (3 mins ago vs 2 mins limit)
  conv_specific_old = Conversation.create!(
    account: account,
    inbox: inbox_specific,
    status: :open,
    contact: contact,
    created_at: 30.minutes.ago
  )
  # Start loop hack to avoid read-only attribute issues if set directly (though created_at usually is fine)
  # Using update_columns to force timestamp changes
  conv_specific_old.update_columns(last_activity_at: 3.minutes.ago, created_at: 30.minutes.ago)

  # Case B: Inbox Specific - NOT old enough (1 min ago vs 2 mins limit)
  conv_specific_new = Conversation.create!(
    account: account,
    inbox: inbox_specific,
    status: :open,
    contact: contact,
    created_at: 30.minutes.ago
  )
  conv_specific_new.update_columns(last_activity_at: 1.minute.ago, created_at: 30.minutes.ago)

  # Case C: Inbox Default - Old enough for Account (15 mins ago vs 10 mins limit)
  conv_default_old = Conversation.create!(
    account: account,
    inbox: inbox_default,
    status: :open,
    contact: contact,
    created_at: 30.minutes.ago
  )
  conv_default_old.update_columns(last_activity_at: 15.minutes.ago, created_at: 30.minutes.ago)

  # Case D: Inbox Default - NOT old enough for Account (5 mins ago vs 10 mins limit)
  conv_default_new = Conversation.create!(
    account: account,
    inbox: inbox_default,
    status: :open,
    contact: contact,
    created_at: 30.minutes.ago
  )
  conv_default_new.update_columns(last_activity_at: 5.minutes.ago, created_at: 30.minutes.ago)

  logger.info 'Created Conversations:'
  logger.info "A (Specific, Old): ID #{conv_specific_old.id}"
  logger.info "B (Specific, New): ID #{conv_specific_new.id}"
  logger.info "C (Default, Old): ID #{conv_default_old.id}"
  logger.info "D (Default, New): ID #{conv_default_new.id}"

  # 3. Run Job
  logger.info 'Running Conversations::ResolutionJob...'
  Conversations::ResolutionJob.perform_now(account: account)

  # 4. Verify Results
  conv_specific_old.reload
  conv_specific_new.reload
  conv_default_old.reload
  conv_default_new.reload

  logger.info '--- Results ---'

  success = true

  # A Should be RESOLVED
  if conv_specific_old.resolved?
    logger.info '✅ Case A: Passed (Resolved)'
  else
    logger.error "❌ Case A: Failed (Expected Resolved, got #{conv_specific_old.status})"
    success = false
  end

  # B Should be OPEN
  if conv_specific_new.open?
    logger.info '✅ Case B: Passed (Open)'
  else
    logger.error "❌ Case B: Failed (Expected Open, got #{conv_specific_new.status})"
    success = false
  end

  # C Should be RESOLVED
  if conv_default_old.resolved?
    logger.info '✅ Case C: Passed (Resolved)'
  else
    logger.error "❌ Case C: Failed (Expected Resolved, got #{conv_default_old.status})"
    success = false
  end

  # D Should be OPEN
  if conv_default_new.open?
    logger.info '✅ Case D: Passed (Open)'
  else
    logger.error "❌ Case D: Failed (Expected Open, got #{conv_default_new.status})"
    success = false
  end

  if success
    logger.info '🎉 ALL TESTS PASSED!'
  else
    logger.error '💥 SOME TESTS FAILED!'
  end

rescue StandardError => e
  logger.error "Error: #{e.message}"
  logger.error e.backtrace.join("\n")
  # Clean up
  raise ActiveRecord::Rollback
end
