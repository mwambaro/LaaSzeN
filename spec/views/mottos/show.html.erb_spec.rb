require 'rails_helper'

RSpec.describe "mottos/show", :type => :view do
  before(:each) do
    @motto = assign(:motto, Motto.create!(
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
