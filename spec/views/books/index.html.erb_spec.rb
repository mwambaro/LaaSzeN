require 'rails_helper'

RSpec.describe "books/index", :type => :view do
  before(:each) do
    assign(:books, [
      Book.create!(
        :language => "Language",
        :author => "Author",
        :theme => "Theme",
        :content => ""
      ),
      Book.create!(
        :language => "Language",
        :author => "Author",
        :theme => "Theme",
        :content => ""
      )
    ])
  end

  it "renders a list of books" do
    render
    assert_select "tr>td", :text => "Language".to_s, :count => 2
    assert_select "tr>td", :text => "Author".to_s, :count => 2
    assert_select "tr>td", :text => "Theme".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
