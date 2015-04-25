json.array!(@books) do |book|
  json.extract! book, :id, :language, :author, :theme, :content
  json.url book_url(book, format: :json)
end
