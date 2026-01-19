class Conversations::ResolutionJob < ApplicationJob
  queue_as :low

  def perform(account:)
    # limiting the number of conversations to be resolved to avoid any performance issues
    resolvable_conversations = conversation_scope(account).limit(Limits::BULK_ACTIONS_LIMIT)
    resolvable_conversations.each do |conversation|
      # send message from bot that conversation has been resolved
      # do this is account.auto_resolve_message is set
      ::MessageTemplates::Template::AutoResolve.new(conversation: conversation).perform if account.auto_resolve_message.present?
      conversation.add_labels(account.auto_resolve_label) if account.auto_resolve_label.present?
      conversation.toggle_status
    end
  end

  private

  def conversation_scope(account)
    ids = []

    # 1. Inboxes with specific configuration
    account.inboxes.where.not(auto_resolve_duration: nil).find_each do |inbox|
      scope = account.conversations.open.where(inbox_id: inbox.id)
      scope = scope.where(waiting_since: nil) if account.auto_resolve_ignore_waiting
      ids += scope.where('last_activity_at < ?', Time.now.utc - inbox.auto_resolve_duration.minutes).limit(Limits::BULK_ACTIONS_LIMIT).pluck(:id)
    end

    # 2. Account level configuration (for inboxes without specific config)
    if account.auto_resolve_after.present?
      inbox_ids_with_config = account.inboxes.where.not(auto_resolve_duration: nil).select(:id)
      scope = account.conversations.open.where.not(inbox_id: inbox_ids_with_config)
      scope = scope.where(waiting_since: nil) if account.auto_resolve_ignore_waiting
      ids += scope.where('last_activity_at < ?', Time.now.utc - account.auto_resolve_after.minutes).limit(Limits::BULK_ACTIONS_LIMIT).pluck(:id)
    end

    Conversation.where(id: ids.uniq)
  end
end
