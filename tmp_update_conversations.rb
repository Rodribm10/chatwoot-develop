# Script to update existing test conversations with Funnel Data
[7, 8, 9, 10, 11, 12, 13, 14, 15].each do |id|
  conv = Conversation.find_by(id: id)
  next unless conv

  puts "Updating Conversation ##{id}..."

  # Find or create insight
  insight = conv.crm_insights.first
  insight ||= conv.crm_insights.create!(
    account_id: conv.account_id,
    contact_id: conv.contact_id,
    status: :success,
    generated_at: Time.current,
    structured_data: {}
  )

  data = insight.structured_data || {}

  # Helper to mock messages if none exist (unlikely for these test ones but safe)
  msg_ids = conv.messages.pluck(:id)

  data['funnel'] = {
    'stage' => 'availability',
    'confidence' => 0.85,
    'reason' => 'Cliente demostrou interesse e perguntou disponibilidade (Simulação).',
    'evidence_message_ids' => msg_ids,
    'updated_at' => Time.current.iso8601
  }

  # Ensure other requisite fields for the sidebar to look 'normal'
  data['summary_text'] = 'Resumo automático para teste do funil (Dados Injetados Manualmente).'
  data['intent'] = 'Reserva Rapida'
  data['urgency'] = 'high'
  data['commercial_status'] = 'Interessado'

  insight.update!(structured_data: data)
  puts "Conversation ##{id} UPDATED successfully."
end
