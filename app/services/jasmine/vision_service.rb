# frozen_string_literal: true

require 'openai'
require 'base64'

class Jasmine::VisionService
  attr_reader :attachment

  def initialize(attachment:)
    @attachment = attachment
  end

  def perform
    return nil unless attachment.image?

    api_key = ENV.fetch('OPENAI_API_KEY', nil)
    return nil if api_key.blank?

    client = OpenAI::Client.new(access_token: api_key)

    image_data = get_image_data
    return nil if image_data.blank?

    response = client.chat(
      parameters: {
        model: 'gpt-4o-mini',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: 'Descreva de forma curta e objetiva o que você vê nesta imagem para um sistema de atendimento.' },
              image_data
            ]
          }
        ],
        max_tokens: 300
      }
    )

    response.dig('choices', 0, 'message', 'content')
  rescue StandardError => e
    Rails.logger.error "[Jasmine::VisionService] Failed to analyze image: #{e.message}"
    nil
  end

  private

  def get_image_data
    # Always return base64 for better compatibility (OpenAI can reach it even if local)
    # and it avoids issues with signed URL expiration or private buckets.
    {
      type: 'image_url',
      image_url: {
        url: "data:#{attachment.file.content_type};base64,#{encode_image}"
      }
    }
  rescue StandardError => e
    Rails.logger.error "[Jasmine::VisionService] Data encoding failed: #{e.message}"
    nil
  end

  def encode_image
    attachment.file.blob.open do |file|
      Base64.strict_encode64(file.read)
    end
  end
end
