require 'rails_helper'

RSpec.describe "intro_texts/edit", :type => :view do
  before(:each) do
    @intro_text = assign(:intro_text, IntroText.create!(
      :language => "MyString",
      :content => ""
    ))
  end

  it "renders the edit intro_text form" do
    render

    assert_select "form[action=?][method=?]", intro_text_path(@intro_text), "post" do

      assert_select "input#intro_text_language[name=?]", "intro_text[language]"

      assert_select "input#intro_text_content[name=?]", "intro_text[content]"
    end
  end
end
