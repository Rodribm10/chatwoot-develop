json.payload do
  json.array! @reservations do |reservation|
    json.partial! 'api/v1/models/captain/reservation', reservation: reservation
  end
end

json.meta do
  json.total_count @reservations_count
  json.page @current_page
end
