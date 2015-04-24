require "rails_helper"

RSpec.describe MottosController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/mottos").to route_to("mottos#index")
    end

    it "routes to #new" do
      expect(:get => "/mottos/new").to route_to("mottos#new")
    end

    it "routes to #show" do
      expect(:get => "/mottos/1").to route_to("mottos#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/mottos/1/edit").to route_to("mottos#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/mottos").to route_to("mottos#create")
    end

    it "routes to #update" do
      expect(:put => "/mottos/1").to route_to("mottos#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/mottos/1").to route_to("mottos#destroy", :id => "1")
    end

  end
end
