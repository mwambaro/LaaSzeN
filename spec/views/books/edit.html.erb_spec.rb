require 'rails_helper'

RSpec.describe "books/edit", :type => :view do
  before(:each) do
    @book = assign(:book, Book.create!(
      :language => "MyString",
      :theme => "MyString",
      :author => "MyString",
      :content => ""
    ))
  end

  it "renders the edit book form" do
    render

    assert_select "form[action=?][method=?]", book_path(@book), "post" do

      assert_select "input#book_language[name=?]", "book[language]"

      assert_select "input#book_theme[name=?]", "book[theme]"

      assert_select "input#book_author[name=?]", "book[author]"

      assert_select "input#book_content[name=?]", "book[content]"
    end
  end
end
