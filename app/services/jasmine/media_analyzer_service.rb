# frozen_string_literal: true

class Jasmine::MediaAnalyzerService
  attr_reader :message

  def initialize(message:)
    @message = message
  end

  def perform
    analyze_audio
    analyze_images
  end

  private

  def analyze_audio
    message.attachments.where(file_type: :audio).find_each do |attachment|
      next if attachment.meta&.dig('transcribed_text').present?

      Rails.logger.info "[Jasmine::MediaAnalyzer] Transcribing audio for Attachment #{attachment.id}"
      # Try to use the standard AudioTranscriptionService (usually in enterprise folder)
      begin
        if defined?(Messages::AudioTranscriptionService)
          # This service updates the attachment meta internally
          Messages::AudioTranscriptionService.new(attachment).perform
        end
      rescue StandardError => e
        Rails.logger.error "[Jasmine::MediaAnalyzer] Audio transcription failed: #{e.message}"
      end
    end
  end

  def analyze_images
    message.attachments.where(file_type: :image).find_each do |attachment|
      next if attachment.meta&.dig('description').present?

      Rails.logger.info "[Jasmine::MediaAnalyzer] Analyzing image for Attachment #{attachment.id}"
      begin
        description = Jasmine::VisionService.new(attachment: attachment).perform
        if description.present?
          new_meta = (attachment.meta || {}).merge('description' => description)
          attachment.update!(meta: new_meta)
          Rails.logger.info "[Jasmine::MediaAnalyzer] Image analysis successful for Attachment #{attachment.id}"
        end
      rescue StandardError => e
        Rails.logger.error "[Jasmine::MediaAnalyzer] Image analysis failed: #{e.message}"
      end
    end
  end
end
