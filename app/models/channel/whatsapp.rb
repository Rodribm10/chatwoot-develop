# == Schema Information
#
# Table name: channel_whatsapp
#
#  id                             :bigint           not null, primary key
#  message_templates              :jsonb
#  message_templates_last_updated :datetime
#  phone_number                   :string           not null
#  provider                       :string           default("default")
#  provider_config                :jsonb
#  wuzapi_admin_token             :string
#  wuzapi_admin_token_iv          :string
#  wuzapi_user_token              :string
#  wuzapi_user_token_iv           :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  account_id                     :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_on_phone_number  (phone_number) UNIQUE
#

class Channel::Whatsapp < ApplicationRecord
  include Channelable
  include Reauthorizable

  self.table_name = 'channel_whatsapp'
  EDITABLE_ATTRS = [:phone_number, :provider, :wuzapi_user_token, :wuzapi_admin_token, { provider_config: {} }].freeze

  # default at the moment is 360dialog lets change later.
  PROVIDERS = %w[default whatsapp_cloud wuzapi baileys zapi].freeze

  encrypts :wuzapi_user_token, :wuzapi_admin_token

  before_validation :ensure_webhook_verify_token
  before_validation :move_tokens_to_encrypted_attributes
  before_validation :provision_wuzapi_user, on: :create

  validates :provider, inclusion: { in: PROVIDERS }
  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config

  after_create :sync_templates
  after_create_commit :setup_webhooks
  after_update_commit :setup_webhooks, if: :webhook_configuration_changed?
  before_destroy :teardown_webhooks

  def name
    'Whatsapp'
  end

  def provider_service
    case provider
    when 'whatsapp_cloud'
      Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: self)
    when 'wuzapi'
      Whatsapp::Providers::WuzapiService.new(whatsapp_channel: self)
    when 'baileys'
      Whatsapp::Providers::WhatsappBaileysService.new(whatsapp_channel: self)
    when 'zapi'
      Whatsapp::Providers::WhatsappZapiService.new(whatsapp_channel: self)
    else
      Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: self)
    end
  end

  def mark_message_templates_updated
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:message_templates_last_updated, Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  delegate :send_message, to: :provider_service
  delegate :send_reaction_message, to: :provider_service
  delegate :send_template, to: :provider_service
  delegate :sync_templates, to: :provider_service
  delegate :media_url, to: :provider_service
  delegate :api_headers, to: :provider_service

  def setup_webhooks
    perform_webhook_setup
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Webhook setup failed: #{e.message}"
    prompt_reauthorization!
  end

  def use_internal_host?
    provider == 'baileys' && ENV.fetch('BAILEYS_PROVIDER_USE_INTERNAL_HOST_URL', false)
  end

  def update_provider_connection!(provider_connection)
    assign_attributes(provider_connection: provider_connection)
    # NOTE: Skip `validate_provider_config?` check
    save!(validate: false)
  end

  def provider_connection_data
    data = { connection: provider_connection['connection'] }
    if Current.account_user&.administrator?
      data[:qr_data_url] = provider_connection['qr_data_url']
      data[:error] = provider_connection['error']
    end
    data
  end

  def toggle_typing_status(typing_status, conversation:)
    return unless provider_service.respond_to?(:toggle_typing_status)

    identifier = conversation.contact.identifier
    phone_number = conversation.contact.phone_number
    recipient_id = identifier || phone_number

    # Debug Log
    Rails.logger.info "[Typing] recipient_id=#{recipient_id.inspect} identifier=#{identifier.inspect} phone=#{phone_number.inspect}"

    # Validation: Ensure recipient_id is E164 compliant (digits only, maybe +).
    # If identifier is something like x@lid, we should fallback to phone_number.
    # Using suggested regex: \A\+?\d{10,15}\z
    unless recipient_id.to_s.gsub(/[\+\s\-\(\)]/, '').match?(/\A\d{10,15}\z/)
      Rails.logger.warn "[Typing] Invalid recipient_id format (#{recipient_id}). Falling back to phone_number: #{phone_number}"
      recipient_id = phone_number
    end

    provider_service.toggle_typing_status(typing_status, last_message: nil, recipient_id: recipient_id)
  end

  def update_presence(status)
    return unless provider_service.respond_to?(:update_presence)

    provider_service.update_presence(status)
  end

  def read_messages(messages, conversation:)
    return unless provider_service.respond_to?(:read_messages)
    # NOTE: This is the default behavior, so `mark_as_read` being `nil` is the same as `true`.
    return if provider_config&.dig('mark_as_read') == false

    recipient_id = if provider == 'zapi'
                     conversation.contact.phone_number
                   else
                     conversation.contact.identifier || conversation.contact.phone_number
                   end

    provider_service.read_messages(messages, recipient_id: recipient_id)
  end

  def unread_conversation(conversation)
    return unless provider_service.respond_to?(:unread_message)

    # NOTE: For the Baileys provider, the last message is required even if it is an outgoing message.
    last_message = conversation.messages.last
    provider_service.unread_message(conversation.contact.phone_number, last_message) if last_message
  end

  def disconnect_channel_provider
    provider_service.disconnect_channel_provider
  rescue StandardError => e
    # NOTE: Don't prevent destruction if disconnect fails
    Rails.logger.error "Failed to disconnect channel provider: #{e.message}"
  end

  def received_messages(messages, conversation)
    return unless provider_service.respond_to?(:received_messages)

    recipient_id = conversation.contact.identifier || conversation.contact.phone_number
    provider_service.received_messages(recipient_id, messages)
  end

  def on_whatsapp(phone_number)
    return unless provider_service.respond_to?(:on_whatsapp)

    provider_service.on_whatsapp(phone_number)
  end

  private

  def webhook_configuration_changed?
    return true if saved_change_to_provider? && provider == 'wuzapi'
    return false unless provider == 'wuzapi'

    saved_change_to_wuzapi_user_token? ||
      (saved_change_to_provider_config? && provider_config['wuzapi_base_url'] != provider_config_before_last_save['wuzapi_base_url'])
  end

  def ensure_webhook_verify_token
    provider_config['webhook_verify_token'] ||= SecureRandom.hex(16) if provider.in?(%w[whatsapp_cloud baileys])
  end

  def move_tokens_to_encrypted_attributes
    return unless provider == 'wuzapi'

    if provider_config['wuzapi_user_token'].present?
      self.wuzapi_user_token = provider_config['wuzapi_user_token']
      provider_config.delete('wuzapi_user_token')
    end

    return unless provider_config['wuzapi_admin_token'].present?

    self.wuzapi_admin_token = provider_config['wuzapi_admin_token']
    provider_config.delete('wuzapi_admin_token')
  end

  def validate_provider_config
    errors.add(:provider_config, 'Invalid Credentials') unless provider_service.validate_provider_config?
  end

  def perform_webhook_setup
    if provider == 'wuzapi'
      return unless inbox.present?

      base_url = provider_config['wuzapi_base_url']
      # Use encrypted token
      user_token = wuzapi_user_token

      return unless user_token.present?

      # Construct Chatwoot Webhook URL
      # Using standard route: /webhooks/whatsapp/:phone_number for WuzAPI as per fix
      app_url = ENV['FRONTEND_URL'].presence || 'http://localhost:3000'
      webhook_url = "#{app_url}/webhooks/whatsapp/#{phone_number}"

      begin
        client = Wuzapi::Client.new(base_url)
        client.set_webhook(user_token, webhook_url)
      rescue StandardError => e
        Rails.logger.error "Wuzapi Webhook Setup Failed: #{e.message}"
      end
    elsif provider_service.respond_to?(:setup_channel_provider)
      provider_service.setup_channel_provider
    else
      # 360Dialog / Cloud logic
      business_account_id = provider_config['business_account_id']
      api_key = provider_config['api_key']

      Whatsapp::WebhookSetupService.new(self, business_account_id, api_key).perform
    end
  end

  def teardown_webhooks
    Whatsapp::WebhookTeardownService.new(self).perform
  end

  def provision_wuzapi_user
    return unless provider == 'wuzapi' && provider_config['auto_create_user']
    return if wuzapi_user_token.present?

    base_url = provider_config['wuzapi_base_url']
    # Use encrypted admin token
    admin_token = wuzapi_admin_token
    user_name = "Chatwoot_#{phone_number}"

    # Helper to attempt provision
    attempt_provision = lambda do |url|
      service = Wuzapi::ProvisioningService.new(url, admin_token)
      service.provision(user_name)
    end

    begin
      result = attempt_provision.call(base_url)
    rescue StandardError => e
      Rails.logger.warn "Wuzapi Provisioning failed with URL #{base_url}: #{e.message}"
      # Fallback: if url ends in /api, strip it and try again
      if base_url.match?(%r{/api/?$})
        fallback_url = base_url.gsub(%r{/api/?$}, '')
        Rails.logger.info "Retrying Wuzapi Provisioning with fallback URL: #{fallback_url}"
        begin
          result = attempt_provision.call(fallback_url)
          # If success, update the config to use the working URL
          provider_config['wuzapi_base_url'] = fallback_url
          Rails.logger.info "Wuzapi Provisioning fallback successful. Updated base_url to #{fallback_url}"
        rescue StandardError => retry_e
          Rails.logger.error "Wuzapi Provisioning fallback also failed: #{retry_e.message}"
          errors.add(:base, "Wuzapi Provisioning Failed: #{retry_e.message}")
          throw(:abort)
        end
      else
        errors.add(:base, "Wuzapi Provisioning Failed: #{e.message}")
        throw(:abort)
      end
    end

    # Success handling
    provider_config['wuzapi_user_id'] = result[:wuzapi_user_id]
    self.wuzapi_user_token = result[:wuzapi_user_token]

    masked_token = result[:wuzapi_user_token].to_s[-4..-1]
    Rails.logger.info "Wuzapi User Provisioned. ID: #{result[:wuzapi_user_id]}, Token (last 4): ****#{masked_token}"
  end
end
