class ActiveLanguageController < ApplicationController
    def active
        active_lang = params[:id]
        LaaszenModel::SiteLanguage.set_active_language(active_lang)
        #@data_model = LaaszenModel::DataModel.new(::Rails.root)
        #a_lang = LaaszenModel::SiteLanguage.get_active_language
        #@data_model.send(:debug_write, "Active Language After Form: #{a_lang}")
        
        redirect_to :back
    end
end
