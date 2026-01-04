module CrmInsights
  class ContactSessionCounter
    WINDOW = 24.hours

    def initialize(conversation)
      @conversation = conversation
    end

    def call
      inbound_times = @conversation.messages
                                   .where(message_type: :incoming, private: false)
                                   .order(:created_at)
                                   .pluck(:created_at)

      count = 0
      last_session_start = nil

      inbound_times.each do |timestamp|
        if last_session_start.nil? || timestamp > last_session_start + WINDOW
          count += 1
          last_session_start = timestamp
        end
      end

      {
        count: count,
        last_contact_at: last_session_start
      }
    end
  end
end
