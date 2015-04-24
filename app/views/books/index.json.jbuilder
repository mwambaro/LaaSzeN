json.array!(@books) do |book|
  json.extract! book, :id, :language, :theme, :author, :content
  json.url book_url(book, format: :json)
end
