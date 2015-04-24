require 'rails_helper'

RSpec.describe "mottos/index", :type => :view do
  before(:each) do
    assign(:mottos, [
      Motto.create!(
        :language => "Language",
        :name => "Name",
        :content => ""
      ),
      Motto.create!(
        :language => "Language",
        :name => "Name",
        :content => ""
      )
    ])
  end

  it "renders a list of mottos" do
    render
    assert_select "tr>td", :text => "Language".to_s, :count => 2
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
