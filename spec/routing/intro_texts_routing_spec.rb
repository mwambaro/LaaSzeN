require "rails_helper"

RSpec.describe IntroTextsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/intro_texts").to route_to("intro_texts#index")
    end

    it "routes to #new" do
      expect(:get => "/intro_texts/new").to route_to("intro_texts#new")
    end

    it "routes to #show" do
      expect(:get => "/intro_texts/1").to route_to("intro_texts#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/intro_texts/1/edit").to route_to("intro_texts#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/intro_texts").to route_to("intro_texts#create")
    end

    it "routes to #update" do
      expect(:put => "/intro_texts/1").to route_to("intro_texts#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/intro_texts/1").to route_to("intro_texts#destroy", :id => "1")
    end

  end
end
