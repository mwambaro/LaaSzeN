json.array!(@mottos) do |motto|
  json.extract! motto, :id, :language, :name, :content
  json.url motto_url(motto, format: :json)
end
