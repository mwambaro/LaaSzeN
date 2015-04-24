
require File.join(::Rails.root, 'app', 'helpers', 'laaszen_model.rb')

class LaaszenTask    
    def LaaszenTask.define_data_model(
            model_name, attributes, code=nil,
            validations="", associations="", 
            callbacks="", others="", 
            bl_ordinary=true, bl_dynamic=false, lang=nil, 
            laaszen_model= nil
        )
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.define_data_model(
            model_name, attributes, code, validations, 
            associations, callbacks, others, 
            bl_ordinary, bl_dynamic, lang
        )
    end
    
    def LaaszenTask.undefine_data_model(file=nil, laaszen_model=nil)
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.undefine_data_model(file)
    end
    
    def LaaszenTask.delete_data_model(file=nil, laaszen_model=nil)
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.delete_data_model(file)
    end
    
    def LaaszenTask.delete_dynamic_data_model(model_name=nil, laaszen_model=nil)
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.delete_dynamic_data_model(model_name)
    end
    
    # N.B: db table is retrieved by call its 'all' method.
    #      Then, an array made of th serialization of each table row
    #      is constituted. The array is assigned to :object column of
    #      the LaaszenSurrogateMother db table.
    # Return: nil/LaaszenSurrogateMother object created.
    def LaaszenTask.inseminate_surrogate(model_name, laaszen_model=nil)
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.inseminate_surrogate(model_name)
    end
    
    # Return: data model class object
    def LaaszenTask.get_db_table_from_surrogate(language, model_name, laaszen_model=nil)
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.get_db_table_from_surrogate(language, model_name)
    end
    
    def LaaszenTask.load_metadata(into_language, laaszen_model=nil)
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.load_metadata(into_language)
    end
    
    def LaaszenTask.manage_graph_state(into_language, metadata, laaszen_model=nil)
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.manage_graph_state(into_language, metadata)
    end
    
    def LaaszenTask.translate(
        into_language, payload={}, laaszen_model=nil, from_language=nil
    )
        from_language ||= 'English'
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.translate(from_language, into_language, payload)
    end
    
    def LaaszenTask.translate_and_persist(
        into_language, payload={}, laaszen_model=nil, from_language=nil
    )
        from_language ||= 'English'
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.translate_and_persist(from_language, into_language, payload)
    end
    
    def LaaszenTask.edit_model_translation(
        into_language, db_table_name, tr_payload={}, laaszen_model=nil
    )
        @laaszen_model = laaszen_model
        @laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        @laaszen_model.edit_model_translation(
            into_language, db_table_name, tr_payload
        )
    end
end
