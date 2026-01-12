json.key_format! camelize: :lower
json.array! @reminders, partial: 'api/v1/accounts/captain/reminders/reminder', as: :reminder
