class WorldCitizenController < ApplicationController
  before_action only: [:home]
  
  def home
    @site_title_text = "World Trade System - Leadership as a Service"
  end
end
