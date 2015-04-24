require 'rails_helper'

RSpec.describe "announcements/new", :type => :view do
  before(:each) do
    assign(:announcement, Announcement.new(
      :language => "MyString",
      :name => "MyString",
      :content => ""
    ))
  end

  it "renders new announcement form" do
    render

    assert_select "form[action=?][method=?]", announcements_path, "post" do

      assert_select "input#announcement_language[name=?]", "announcement[language]"

      assert_select "input#announcement_name[name=?]", "announcement[name]"

      assert_select "input#announcement_content[name=?]", "announcement[content]"
    end
  end
end
