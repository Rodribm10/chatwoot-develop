json.id reservation.id
json.inbox_id reservation.inbox_id
json.contact_id reservation.contact_id
json.contact_inbox_id reservation.contact_inbox_id
json.conversation_id reservation.conversation_id
json.contact_name reservation.contact_name
json.contact_cpf reservation.contact&.custom_attributes&.fetch('cpf', nil)
json.suite_identifier reservation.suite_identifier
json.check_in_at reservation.check_in_at&.iso8601
json.check_out_at reservation.check_out_at&.iso8601
json.status reservation.status
json.payment_status reservation.payment_status
json.total_amount reservation.total_amount
json.unit do
  json.partial! 'api/v1/models/captain/unit', unit: reservation.unit if reservation.unit
end
json.created_at reservation.created_at.to_i
json.updated_at reservation.updated_at.to_i
