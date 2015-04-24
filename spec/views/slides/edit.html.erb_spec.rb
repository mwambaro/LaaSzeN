require 'rails_helper'

RSpec.describe "slides/edit", :type => :view do
  before(:each) do
    @slide = assign(:slide, Slide.create!(
      :language => "MyString",
      :author => "MyString",
      :theme => "MyString",
      :topic => "MyString",
      :content => ""
    ))
  end

  it "renders the edit slide form" do
    render

    assert_select "form[action=?][method=?]", slide_path(@slide), "post" do

      assert_select "input#slide_language[name=?]", "slide[language]"

      assert_select "input#slide_author[name=?]", "slide[author]"

      assert_select "input#slide_theme[name=?]", "slide[theme]"

      assert_select "input#slide_topic[name=?]", "slide[topic]"

      assert_select "input#slide_content[name=?]", "slide[content]"
    end
  end
end
