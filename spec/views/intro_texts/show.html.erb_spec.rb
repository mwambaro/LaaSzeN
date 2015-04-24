require 'rails_helper'

RSpec.describe "intro_texts/show", :type => :view do
  before(:each) do
    @intro_text = assign(:intro_text, IntroText.create!(
      :language => "Language",
      :content => ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Language/)
    expect(rendered).to match(//)
  end
end
