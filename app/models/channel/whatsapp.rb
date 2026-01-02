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
  PROVIDERS = %w[default whatsapp_cloud wuzapi].freeze
  
  encrypts :wuzapi_user_token, :wuzapi_admin_token

  before_validation :ensure_webhook_verify_token
  before_validation :move_tokens_to_encrypted_attributes
  before_validation :provision_wuzapi_user, on: :create

  validates :provider, inclusion: { in: PROVIDERS }
  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config

  after_create :sync_templates
  after_create_commit :setup_webhooks
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

  private

  def ensure_webhook_verify_token
    provider_config['webhook_verify_token'] ||= SecureRandom.hex(16) if provider == 'whatsapp_cloud'
  end

  def move_tokens_to_encrypted_attributes
    return unless provider == 'wuzapi'

    if provider_config['wuzapi_user_token'].present?
      self.wuzapi_user_token = provider_config['wuzapi_user_token']
      provider_config.delete('wuzapi_user_token')
    end

    if provider_config['wuzapi_admin_token'].present?
      self.wuzapi_admin_token = provider_config['wuzapi_admin_token']
      provider_config.delete('wuzapi_admin_token')
    end
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
      if base_url.match?(/\/api\/?$/)
        fallback_url = base_url.gsub(/\/api\/?$/, '')
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
