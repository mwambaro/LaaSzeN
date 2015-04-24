require 'rails_helper'

RSpec.describe "slides/index", :type => :view do
  before(:each) do
    assign(:slides, [
      Slide.create!(
        :language => "Language",
        :author => "Author",
        :theme => "Theme",
        :topic => "Topic",
        :content => ""
      ),
      Slide.create!(
        :language => "Language",
        :author => "Author",
        :theme => "Theme",
        :topic => "Topic",
        :content => ""
      )
    ])
  end

  it "renders a list of slides" do
    render
    assert_select "tr>td", :text => "Language".to_s, :count => 2
    assert_select "tr>td", :text => "Author".to_s, :count => 2
    assert_select "tr>td", :text => "Theme".to_s, :count => 2
    assert_select "tr>td", :text => "Topic".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
