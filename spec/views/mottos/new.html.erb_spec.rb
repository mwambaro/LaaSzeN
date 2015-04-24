require 'rails_helper'

RSpec.describe "mottos/new", :type => :view do
  before(:each) do
    assign(:motto, Motto.new(
      :language => "MyString",
      :name => "MyString",
      :content => ""
    ))
  end

  it "renders new motto form" do
    render

    assert_select "form[action=?][method=?]", mottos_path, "post" do

      assert_select "input#motto_language[name=?]", "motto[language]"

      assert_select "input#motto_name[name=?]", "motto[name]"

      assert_select "input#motto_content[name=?]", "motto[content]"
    end
  end
end
