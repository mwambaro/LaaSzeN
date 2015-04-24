require 'rails_helper'

RSpec.describe "slides/new", :type => :view do
  before(:each) do
    assign(:slide, Slide.new(
      :language => "MyString",
      :author => "MyString",
      :theme => "MyString",
      :topic => "MyString",
      :content => ""
    ))
  end

  it "renders new slide form" do
    render

    assert_select "form[action=?][method=?]", slides_path, "post" do

      assert_select "input#slide_language[name=?]", "slide[language]"

      assert_select "input#slide_author[name=?]", "slide[author]"

      assert_select "input#slide_theme[name=?]", "slide[theme]"

      assert_select "input#slide_topic[name=?]", "slide[topic]"

      assert_select "input#slide_content[name=?]", "slide[content]"
    end
  end
end
