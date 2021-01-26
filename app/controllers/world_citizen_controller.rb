class WorldCitizenController < ApplicationController
  before_action only: [:home]
  
  def home
    @site_title_text = "World Trade System - Leadership as a Service"
    @mission_section_card_title = "Mission"
    @publication_section_card_title = "Publications"
  end
end
