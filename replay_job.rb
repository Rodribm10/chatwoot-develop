# Replay the job from the logs
puts 'Starting Manual Job Replay...'

params = {
  'event' => {
    'Info' => {
      'AddressingMode' => '',
      'BroadcastListOwner' => '',
      'BroadcastRecipients' => nil,
      'Category' => '',
      'Chat' => '556182098580@s.whatsapp.net',
      'DeviceSentMeta' => nil,
      'Edit' => '',
      'ID' => '3AC14BFBC42535292176',
      'IsFromMe' => false,
      'IsGroup' => false,
      'MediaType' => '',
      'MsgBotInfo' => {
        'EditSenderTimestampMS' => '0001-01-01T00:00:00Z',
        'EditTargetID' => '',
        'EditType' => ''
      },
      'MsgMetaInfo' => {
        'DeprecatedLIDSession' => nil,
        'TargetChat' => '',
        'TargetID' => '',
        'TargetSender' => '',
        'ThreadMessageID' => '',
        'ThreadMessageSenderJID' => ''
      },
      'Multicast' => false,
      'PushName' => '😅‼️',
      'RecipientAlt' => '',
      'Sender' => '556182098580@s.whatsapp.net',
      'SenderAlt' => '206141334237397@lid',
      'ServerID' => 0,
      'Timestamp' => '2026-01-01T21:28:56-03:00',
      'Type' => 'text',
      'VerifiedName' => nil
    },
    'IsBotInvoke' => false,
    'IsDocumentWithCaption' => false,
    'IsEdit' => false,
    'IsEphemeral' => false,
    'IsLottieSticker' => false,
    'IsViewOnce' => false,
    'IsViewOnceV2' => false,
    'IsViewOnceV2Extension' => false,
    'Message' => {
      'conversation' => 'Teste bug',
      'messageContextInfo' => {
        'deviceListMetadata' => {
          'recipientKeyHash' => 'R2rnkO4XfzfeeA==',
          'recipientTimestamp' => 1_766_808_767,
          'senderTimestamp' => 1_767_309_244
        },
        'deviceListMetadataVersion' => 2,
        'messageSecret' => '3ikQlL6tlP/RK1tKdu1SC4eIeXyawuSf6fAMgL+09AA='
      }
    },
    'NewsletterMeta' => nil,
    'RawMessage' => {
      'conversation' => 'Teste bug',
      'messageContextInfo' => {
        'deviceListMetadata' => {
          'recipientKeyHash' => 'R2rnkO4XfzfeeA==',
          'recipientTimestamp' => 1_766_808_767,
          'senderTimestamp' => 1_767_309_244
        },
        'deviceListMetadataVersion' => 2,
        'messageSecret' => '3ikQlL6tlP/RK1tKdu1SC4eIeXyawuSf6fAMgL+09AA='
      }
    },
    'RetryCount' => 0,
    'SourceWebMsg' => nil,
    'UnavailableRequestID' => ''
  },
  'token' => 'cacf8e3ba424bdfaeb3593e1d5a4babca211c833baf3928353e6e71f312d6e53',
  'type' => 'Message',
  'controller' => 'webhooks/whatsapp',
  'action' => 'process_payload',
  'phone_number' => '5561991544165'
}

# Ensure logger prints to stdout
Rails.logger = Logger.new(STDOUT)

puts '--- Execution Start ---'
begin
  Webhooks::WhatsappEventsJob.perform_now(params)
rescue StandardError => e
  puts "🔥 ERROR: #{e.message}"
  puts e.backtrace
end
puts '--- Execution End ---'

# Verify DB
puts '--- Verification ---'
phone = '556182098580'
normalized = "+#{phone}"
contact = Contact.find_by(phone_number: normalized)

if contact
  puts "✅ Contact Found: #{contact.name} (ID: #{contact.id})"
  conv = Conversation.where(contact_id: contact.id).last
  if conv
    puts "✅ Conversation Found: ID #{conv.id}"
    msg = conv.messages.last
    if msg
      puts "✅ Message Found: '#{msg.content}' (ID: #{msg.id})"
    else
      puts '❌ Conversation exists but NO Message found.'
    end
  else
    puts '❌ Contact exists but NO Conversation found.'
  end
else
  puts "❌ Contact NOT found for #{normalized}"
  puts 'Checking if non-normalized exists...'
  c2 = Contact.find_by(phone_number: phone)
  puts c2 ? "⚠️ Found contact without +: #{c2.name}" : '❌ No contact found at all.'
end
