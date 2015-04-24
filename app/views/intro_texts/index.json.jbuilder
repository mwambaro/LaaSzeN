json.array!(@intro_texts) do |intro_text|
  json.extract! intro_text, :id, :language, :content
  json.url intro_text_url(intro_text, format: :json)
end
