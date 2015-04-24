require 'rails_helper'

RSpec.describe "mottos/edit", :type => :view do
  before(:each) do
    @motto = assign(:motto, Motto.create!(
      :language => "MyString",
      :name => "MyString",
      :content => ""
    ))
  end

  it "renders the edit motto form" do
    render

    assert_select "form[action=?][method=?]", motto_path(@motto), "post" do

      assert_select "input#motto_language[name=?]", "motto[language]"

      assert_select "input#motto_name[name=?]", "motto[name]"

      assert_select "input#motto_content[name=?]", "motto[content]"
    end
  end
end
