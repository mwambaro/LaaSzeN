json.array!(@announcements) do |announcement|
  json.extract! announcement, :id, :language, :name, :content
  json.url announcement_url(announcement, format: :json)
end
