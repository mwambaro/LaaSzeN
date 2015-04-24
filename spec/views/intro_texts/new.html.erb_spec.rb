require 'rails_helper'

RSpec.describe "intro_texts/new", :type => :view do
  before(:each) do
    assign(:intro_text, IntroText.new(
      :language => "MyString",
      :content => ""
    ))
  end

  it "renders new intro_text form" do
    render

    assert_select "form[action=?][method=?]", intro_texts_path, "post" do

      assert_select "input#intro_text_language[name=?]", "intro_text[language]"

      assert_select "input#intro_text_content[name=?]", "intro_text[content]"
    end
  end
end
