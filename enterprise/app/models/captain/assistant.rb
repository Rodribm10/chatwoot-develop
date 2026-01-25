# == Schema Information
#
# Table name: captain_assistants
#
#  id                  :bigint           not null, primary key
#  config              :jsonb            not null
#  description         :string
#  guardrails          :jsonb
#  name                :string           not null
#  response_guidelines :jsonb
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  account_id          :bigint           not null
#
# Indexes
#
#  index_captain_assistants_on_account_id  (account_id)
#
class Captain::Assistant < ApplicationRecord
  include Avatarable
  include Concerns::CaptainToolsHelpers
  include Concerns::Agentable

  self.table_name = 'captain_assistants'

  belongs_to :account
  has_many :documents, class_name: 'Captain::Document', dependent: :destroy_async
  has_many :responses, class_name: 'Captain::AssistantResponse', dependent: :destroy_async
  has_many :tool_configs, class_name: 'Captain::ToolConfig', foreign_key: 'captain_assistant_id', dependent: :destroy_async
  has_many :captain_inboxes,
           class_name: 'CaptainInbox',
           foreign_key: :captain_assistant_id,
           dependent: :destroy_async
  has_many :inboxes,
           through: :captain_inboxes
  has_many :messages, as: :sender, dependent: :nullify
  has_many :copilot_threads, dependent: :destroy_async
  has_many :scenarios, class_name: 'Captain::Scenario', dependent: :destroy_async

  store_accessor :config, :temperature, :feature_faq, :feature_memory, :product_name, :role_name, :playbook, :distance_threshold, :max_rag_results,
                 :allow_handoff

  validates :name, presence: true
  validates :description, presence: true
  validates :account_id, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  scope :for_account, ->(account_id) { where(account_id: account_id) }

  def available_name
    name
  end

  def available_agent_tools
    tools = self.class.built_in_agent_tools.dup

    custom_tools = account.captain_custom_tools.enabled.map(&:to_tool_metadata)
    tools.concat(custom_tools)

    tools
  end

  def available_tool_ids
    available_agent_tools.pluck(:id)
  end

  def push_event_data
    {
      id: id,
      name: name,
      avatar_url: avatar_url.presence || default_avatar_url,
      description: description,
      created_at: created_at,
      type: 'captain_assistant'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      avatar_url: avatar_url.presence || default_avatar_url,
      description: description,
      created_at: created_at,
      type: 'captain_assistant'
    }
  end

  def pubsub_token
    "captain_assistant_#{id}"
  end

  def agent_tools(conversation: nil, user: nil)
    tools = [
      self.class.resolve_tool_class('faq_lookup').new(self, conversation: conversation, user: user)
    ]
    tools << self.class.resolve_tool_class('handoff').new(self, conversation: conversation, user: user) if allow_handoff_enabled?

    # Add each enabled scenario as a tool
    scenarios.enabled.each do |scenario|
      tools << Captain::Tools::ScenarioDelegatorTool.new(scenario, user: user, conversation: conversation)
    end

    # Add enabled built-in tools
    tool_configs.where(is_enabled: true).each do |tool_config|
      tool_class = self.class.resolve_tool_class(tool_config.tool_key)
      next unless tool_class

      # Avoid duplicates if tool is already added (e.g. hardcoded ones)
      next if tools.any?(tool_class)

      tools << tool_class.new(self, conversation: conversation, user: user)
    end

    # Add enabled custom tools
    account.captain_custom_tools.enabled.each do |custom_tool|
      tools << Captain::Tools::HttpTool.new(self, custom_tool)
    end

    tools
  end

  def allow_handoff_enabled?
    value = config['allow_handoff']
    return true if value.nil?

    value == true || value.to_s == 'true'
  end

  def prompt_context
    {
      name: name,
      description: description,
      product_name: config['product_name'] || 'this product',
      current_date: Time.zone.today.strftime('%A, %B %d, %Y'),
      system_prompt_blocks: config['system_prompt_blocks'] || [],
      scenarios: scenarios.enabled.map do |scenario|
        {
          title: scenario.title,
          key: scenario.title.parameterize.underscore,
          description: scenario.description
        }
      end,
      response_guidelines: response_guidelines || [],
      guardrails: guardrails || []
    }
  end

  private

  def agent_name
    name.parameterize(separator: '_')
  end

  def default_avatar_url
    "#{ENV.fetch('FRONTEND_URL', nil)}/assets/images/dashboard/captain/logo.svg"
  end
end
