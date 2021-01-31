class WorldCitizenController < ApplicationController
  before_action only: [:home]
  
  def home
    @logo_text = "Laastras"
    @site_title_text = "Leadership as a Service Trade System"
    @mission_section_title = "Mission"
    @social_impact_section_title = "Social Impact"
    @publication_section_title = "Publications"
  end

  def social_impact_cards
    @social_impact = [
        { title: "Government Institution",
          img_src: "",
          description: ""
        },
        { title: "United Nations",
          img_src: "",
          description: ""
        },
        { title: "Associations",
          img_src: "",
          description: ""
        },
        { title: "Enterprises",
          img_src: "",
          description: ""
        }
    ]
  end
end
