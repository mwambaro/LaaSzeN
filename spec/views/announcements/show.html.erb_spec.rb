require 'rails_helper'

RSpec.describe "announcements/show", :type => :view do
  before(:each) do
    @announcement = assign(:announcement, Announcement.create!(
      :language => "Language",
      :name => "Name",
      :content => ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Language/)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
  end
end
