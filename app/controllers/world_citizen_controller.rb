class WorldCitizenController < ApplicationController
  before_action only: [:home]
  
  def home
    @language = "English"
    @logo_text = "Laastras"
    @site_capture_title = "Leadership as a Service Trade System"
    @site_capture_text = "Equal opportunities, equal worth, employer, and employee, every human individual has equal right to every resource that sustains and support human existence"
    @mission_section_title = "Mission"
    @social_impact_section_title = "Social Impact"
    @publication_section_title = "Publications"
  end

  def language
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
