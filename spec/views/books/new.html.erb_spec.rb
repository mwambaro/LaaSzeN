require 'rails_helper'

RSpec.describe "books/new", :type => :view do
  before(:each) do
    assign(:book, Book.new(
      :language => "MyString",
      :theme => "MyString",
      :author => "MyString",
      :content => ""
    ))
  end

  it "renders new book form" do
    render

    assert_select "form[action=?][method=?]", books_path, "post" do

      assert_select "input#book_language[name=?]", "book[language]"

      assert_select "input#book_theme[name=?]", "book[theme]"

      assert_select "input#book_author[name=?]", "book[author]"

      assert_select "input#book_content[name=?]", "book[content]"
    end
  end
end
