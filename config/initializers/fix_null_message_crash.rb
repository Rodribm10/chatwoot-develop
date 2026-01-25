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
      # We check .any? and .size to be robust against unsaved attachments in some contexts.
      return if content.present? || attachments.any?

      # Identifica a origem para um fallback mais inteligente
      if incoming?
        # Casos onde o cliente envia mídias/eventos não suportados ou vazios
        event_info = content_attributes&.dig('event_type')
        self.content = event_info.present? ? "(Evento de plataforma: #{event_info})" : '(Conteúdo ou Mídia não processada)'
      else
        # Casos onde o assistente ou sistema falhou em gerar texto
        self.content = '(O assistente tentou enviar uma resposta vazia)'
      end

      # Log rico para depuração futura
      Rails.logger.warn "⚠️ [DEFENSIVE FIX] #{message_type.upcase} message (ID: #{id || 'new'}) would have crashed Chatwoot!"
      Rails.logger.warn "   - Context: Channel=#{inbox&.channel_type} | AccountID=#{account_id}"
      Rails.logger.warn "   - Attributes: #{attributes.except('content').inspect}"
    end
  end
end
