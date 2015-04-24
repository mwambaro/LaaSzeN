class ActiveLanguageController < ApplicationController
    def active
        active_lang = site_language_params[:active]
        LaaszenModel::SiteLanguage.set_active_language(active_lang)
        #@data_model = LaaszenModel::DataModel.new(::Rails.root)
        #a_lang = LaaszenModel::SiteLanguage.get_active_language
        #@data_model.send(:debug_write, "Active Language After Form: #{a_lang}")
        
        redirect_to :back
    end
  
    private
  
    # Never trust parameters from the scary internet, only allow the white list through.
    def site_language_params
      params.require(:site_language).permit(:active)
    end
end
