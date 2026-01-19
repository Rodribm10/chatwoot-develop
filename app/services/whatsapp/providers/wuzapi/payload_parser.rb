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
                  sender = params.dig(:event, :Info, :Sender)
                  sender_alt = params.dig(:event, :Info, :SenderAlt)

                  # Prefer @s.whatsapp.net over @lid
                  if sender&.include?('@s.whatsapp.net')
                    sender
                  elsif sender_alt&.include?('@s.whatsapp.net')
                    sender_alt
                  else
                    sender
                  end
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
