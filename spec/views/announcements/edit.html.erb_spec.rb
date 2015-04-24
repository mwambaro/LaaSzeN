require 'rails_helper'

RSpec.describe "announcements/edit", :type => :view do
  before(:each) do
    @announcement = assign(:announcement, Announcement.create!(
      :language => "MyString",
      :name => "MyString",
      :content => ""
    ))
  end

  it "renders the edit announcement form" do
    render

    assert_select "form[action=?][method=?]", announcement_path(@announcement), "post" do

      assert_select "input#announcement_language[name=?]", "announcement[language]"

      assert_select "input#announcement_name[name=?]", "announcement[name]"

      assert_select "input#announcement_content[name=?]", "announcement[content]"
    end
  end
end
