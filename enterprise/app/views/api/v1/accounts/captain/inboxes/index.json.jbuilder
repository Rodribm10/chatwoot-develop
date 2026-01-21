json.payload do
  json.array! @captain_inboxes do |captain_inbox|
    json.partial! 'api/v1/models/inbox', resource: captain_inbox.inbox
    json.captain_inbox do
      json.id captain_inbox.id
      json.captain_assistant_id captain_inbox.captain_assistant_id
      json.captain_unit_id captain_inbox.captain_unit_id
      json.always_use_reminder_tool captain_inbox.always_use_reminder_tool
    end
  end
end

json.meta do
  json.total_count @captain_inboxes.size
  json.page 1
end
