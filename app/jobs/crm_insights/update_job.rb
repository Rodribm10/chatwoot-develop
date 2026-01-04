module CrmInsights
  class UpdateJob < ApplicationJob
    queue_as :low

    def perform(conversation_id, reason: nil)
      conversation = Conversation.find_by(id: conversation_id)
      return unless conversation

      if reason == 'idle'
        last_activity_at = conversation.last_activity_at
        return if last_activity_at.present? && last_activity_at > 30.minutes.ago
      end

      UpdateService.new(conversation: conversation, reason: reason).call
    end
  end
end
