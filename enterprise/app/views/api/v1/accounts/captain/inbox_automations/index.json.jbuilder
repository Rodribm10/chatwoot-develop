json.payload do
  json.array! @automations do |automation|
    json.partial! 'api/v1/models/captain/inbox_automation', automation: automation
  end
end

json.meta do
  json.total_count @automations_count
  json.page @current_page
end
