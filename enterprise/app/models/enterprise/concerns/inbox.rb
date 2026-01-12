module Enterprise::Concerns::Inbox
  extend ActiveSupport::Concern

  included do
    has_one :captain_inbox, dependent: :destroy, class_name: 'CaptainInbox'
    has_one :captain_assistant,
            through: :captain_inbox,
            class_name: 'Captain::Assistant'
    has_one :captain_inbox_reminder_setting, dependent: :destroy, class_name: 'Captain::InboxReminderSetting'
    has_many :captain_inbox_automations, dependent: :destroy, class_name: 'Captain::InboxAutomation'
    has_many :inbox_capacity_limits, dependent: :destroy
  end
end
