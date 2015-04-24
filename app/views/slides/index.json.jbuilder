json.array!(@slides) do |slide|
  json.extract! slide, :id, :language, :author, :theme, :topic, :content
  json.url slide_url(slide, format: :json)
end
