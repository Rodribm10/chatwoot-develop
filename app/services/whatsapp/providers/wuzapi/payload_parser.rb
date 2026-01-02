module Whatsapp
  module Providers
    module Wuzapi
      class PayloadParser
        attr_reader :params

        def initialize(params)
          @params = params
        end

        def external_id
          params.dig(:event, :Info, :ID)
        end

        def from_me?
          params.dig(:event, :Info, :IsFromMe)
        end

        def message_type
          type = params.dig(:event, :Info, :Type)
          type == 'text' ? :text : :unknown
        end

        def text_content
          params.dig(:event, :Message, :conversation)
        end

        def sender_phone_number
          jid = if from_me?
                  params.dig(:event, :Info, :Chat)
                else
                  params.dig(:event, :Info, :Sender)
                end
          # Format: 556182098580@s.whatsapp.net -> 556182098580
          jid&.split('@')&.first
        end

        def timestamp
          timestamp_val = params.dig(:event, :Info, :Timestamp)
          return Time.current if timestamp_val.blank?

          begin
            Time.parse(timestamp_val.to_s)
          rescue ArgumentError
            Time.current
          end
        end

        def push_name
          params.dig(:event, :Info, :PushName)
        end

        def group_message?
          params.dig(:event, :Info, :IsGroup)
        end
      end
    end
  end
end
