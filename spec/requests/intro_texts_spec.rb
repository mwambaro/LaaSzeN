require 'rails_helper'

RSpec.describe "IntroTexts", :type => :request do
  describe "GET /intro_texts" do
    it "works! (now write some real specs)" do
      get intro_texts_path
      expect(response).to have_http_status(200)
    end
  end
end
