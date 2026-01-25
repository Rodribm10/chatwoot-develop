class Captain::Tools::ListReservationsTool < Captain::Tools::BasePublicTool
  def name
    'list_reservations'
  end

  def description
    'Lista as reservas recentes do contato atual para consulta.'
  end

  def perform(tool_context, **args)
    _actual_params = resolve_params([args], {})
    conversation = @conversation || find_conversation_from_context(tool_context)
    return 'Erro: Contexto de conversa nao disponivel.' unless conversation

    reservations = Captain::Reservation
                   .where(conversation_id: conversation.id)
                   .or(Captain::Reservation.where(contact_id: conversation.contact_id))
                   .order(check_in_at: :desc)
                   .limit(5)

    return 'Nenhuma reserva encontrada para este contato.' if reservations.blank?

    formatted = reservations.map do |reservation|
      unit_name = reservation.unit&.name || 'unidade indefinida'
      check_in = reservation.check_in_at&.strftime('%d/%m/%Y %H:%M')
      status = reservation.status
      payment = reservation.payment_status
      "ID #{reservation.id} - #{reservation.suite_identifier} - #{check_in} - #{unit_name} - status: #{status} - pagamento: #{payment}"
    end

    "Reservas recentes:\n#{formatted.join("\n")}"
  end

  private

  def find_conversation_from_context(tool_context)
    state = resolve_context(tool_context)
    conversation_id = state.dig(:conversation, :id)
    return nil unless conversation_id

    ::Conversation.find_by(id: conversation_id)
  end
end
