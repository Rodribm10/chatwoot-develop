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
          is_api_from_me = params.dig(:event, :Info, :IsFromMe) || params.dig(:event, :IsFromMe)

          # If Wuzapi says it's NOT from me, believe it.
          return false unless is_api_from_me

          # If Wuzapi says it IS from me, verify against the instance phone number (if available)
          # This protects against false positives where incoming messages are flagged as from_me
          instance_phone = params['phone_number']
          sender_jid = params.dig(:event, :Info, :Sender) || params.dig(:event, :Sender)

          # If we have both numbers, double check
          if instance_phone.present? && sender_jid.present?
            sender_phone = sender_jid.split('@').first
            # If sender is NOT the instance, it CANNOT be from me.
            return false if sender_phone != instance_phone
          end

          true
        end

        def message_type
          return :chat_presence if params['type'] == 'ChatPresence'

          type = params.dig(:event, :Info, :Type)
          type == 'text' ? :text : :unknown
        end

        def presence_state
          params.dig(:event, :State)
        end

        def text_content
          params.dig(:event, :Message, :conversation)
        end

        def sender_phone_number
          jid = extract_jid

          # Reject LIDs as they aren't valid E164 phone numbers
          return nil if jid.blank? || jid.include?('@lid')

          # Format: 556182098580@s.whatsapp.net -> 556182098580
          jid.split('@').first
        end

        def timestamp
          timestamp_val = params.dig(:event, :Info, :Timestamp) || params.dig(:event, :Timestamp)
          return Time.current if timestamp_val.blank?

          begin
            Time.parse(timestamp_val.to_s)
          rescue ArgumentError
            Time.current
          end
        end

        def push_name
          params.dig(:event, :Info, :PushName) || params.dig(:event, :PushName)
        end

        def group_message?
          params.dig(:event, :Info, :IsGroup) || params.dig(:event, :IsGroup)
        end

        private

        def extract_jid
          if from_me?
            params.dig(:event, :Info, :Chat) || params.dig(:event, :Chat)
          else
            sender = params.dig(:event, :Info, :Sender) || params.dig(:event, :Sender)
            sender_alt = params.dig(:event, :Info, :SenderAlt) || params.dig(:event, :SenderAlt)

            # Prefer @s.whatsapp.net over @lid
            if sender&.include?('@s.whatsapp.net')
              sender
            elsif sender_alt&.include?('@s.whatsapp.net')
              sender_alt
            else
              sender
            end
          end
        end
      end
    end
  end
end
