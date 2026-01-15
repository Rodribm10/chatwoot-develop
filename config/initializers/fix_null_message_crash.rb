# config/initializers/fix_null_message_crash.rb
#
# HOTFIX: Prevent ActiveRecord::RecordInvalid: Validation failed: Text and attachments cannot be both nil
# This initializer adds a defensive callback to the Message model to ensure content is never nil.
# It logs the occurrence so we can find the root cause (tool or callback) causing this.

Rails.application.config.to_prepare do
  Message.class_eval do
    before_validation :ensure_content_presence_defensive

    private

    def ensure_content_presence_defensive
      # If content is present, or we have attachments, we are good.
      return if content.present? || attachments.any?

      # If we are here, we are about to crash.
      # Set a default content message and log it.

      Rails.logger.warn "⚠️ [DEFENSIVE FIX] Message would have crashed! Validations: 'Text and attachments cannot be both nil'."
      Rails.logger.warn "   - Caller: #{caller[0..5].join("\n   - ")}"
      Rails.logger.warn "   - Attributes: #{attributes.inspect}"

      self.content = '(System Message - Auto-fixed empty content)'
    end
  end
end
