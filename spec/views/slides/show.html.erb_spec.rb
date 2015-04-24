require 'rails_helper'

RSpec.describe "slides/show", :type => :view do
  before(:each) do
    @slide = assign(:slide, Slide.create!(
      :language => "Language",
      :author => "Author",
      :theme => "Theme",
      :topic => "Topic",
      :content => ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Language/)
    expect(rendered).to match(/Author/)
    expect(rendered).to match(/Theme/)
    expect(rendered).to match(/Topic/)
    expect(rendered).to match(//)
  end
end
