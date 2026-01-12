json.payload do
  json.array! @assets do |asset|
    json.partial! 'api/v1/models/captain/asset', asset: asset
  end
end

json.meta do
  json.total_count @assets_count
  json.page @current_page
end
