require 'rails_helper'

RSpec.describe "announcements/index", :type => :view do
  before(:each) do
    assign(:announcements, [
      Announcement.create!(
        :language => "Language",
        :name => "Name",
        :content => ""
      ),
      Announcement.create!(
        :language => "Language",
        :name => "Name",
        :content => ""
      )
    ])
  end

  it "renders a list of announcements" do
    render
    assert_select "tr>td", :text => "Language".to_s, :count => 2
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
