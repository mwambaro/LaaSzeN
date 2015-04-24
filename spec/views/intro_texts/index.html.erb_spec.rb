require 'rails_helper'

RSpec.describe "intro_texts/index", :type => :view do
  before(:each) do
    assign(:intro_texts, [
      IntroText.create!(
        :language => "Language",
        :content => ""
      ),
      IntroText.create!(
        :language => "Language",
        :content => ""
      )
    ])
  end

  it "renders a list of intro_texts" do
    render
    assert_select "tr>td", :text => "Language".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
