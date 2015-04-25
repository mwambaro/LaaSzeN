require 'rails_helper'

RSpec.describe WorldCitizenController, :type => :controller do

  describe "GET on WorldCitizenController" do
    it "should have :home that returns http success" do
      get :home
      expect(response).to have_http_status(:success)
    end
    
    it "should have :next_slide that returns http success" do
      get :next_slide
      expect(response).to have_http_status(:success)
    end
    
    it "should have :prev_slide that returns http success" do
      get :prev_slide
      expect(response).to have_http_status(:success)
    end
    
    it "should have :next_motto that returns http success" do
      get :next_motto
      expect(response).to have_http_status(:success)
    end
    
    it "should have :prev_motto that returns http success" do
      get :prev_motto
      expect(response).to have_http_status(:success)
    end
    
    it "should have :next_ann that returns http success" do
      get :next_ann
      expect(response).to have_http_status(:success)
    end
    
    it "should have :prev_ann that returns http success" do
      get :prev_ann
      expect(response).to have_http_status(:success)
    end
  end

end
