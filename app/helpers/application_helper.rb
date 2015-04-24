
require 'dry_file_mgr'
require 'translation_session'

module ApplicationHelper   
    def dav_gen_hash_header(title, navs, intro, logos, banner_img)
        DavidEgan.new.dav_gen_hash_header(
            title, navs, intro, logos, banner_img
        )
    end
    
    def dav_gen_hash_content(left_column, right_column)
        DavidEgan.new.dav_gen_hash_content(left_column, right_column)
    end
    
    def dav_gen_hash_footer(footers)
        DavidEgan.new.dav_gen_hash_footer(footers)
    end
    
    def make_dav_layout_compatible(src_file)
        DavidEgan.new.make_dav_layout_compatible(src_file)
    end
    
    # Assumption: 'model' must be a data model that has 'content'
    #             attribute necessarily
    def text_content_wrapper(model)
        text = ""
        unless model.nil?
            @text = model.content.to_s.split("\n")   
            @toc = false 
            @p_header = false 
            @data = nil  
            
            @text.each do |p| 
                if p =~ /^\s*<toc>\s*/i 
                    @toc = true 
                end
                 
                unless @toc 
                    @data ||= ""
                    data = ""
                    if p =~ /\A\s*#\s*[\W\d]*(.*)\z/i  
                        @p_header = true 
                        data = $1.chomp 
                    else 
                        data = p.chomp 
                    end
                    @data += "#{data}\r\n" 
                end 
                
                if @p_header  
                    @p_header = false 
                end 
                    
                if p =~ /\A\s*<\/toc>\s*\z/i 
                    @toc = false 
                end 
            end
            text = @data 
        end
        
        return text
    end
    
    # Assumption: '#' marks start of a header of some form, like chapters.
    #             so text will lie between number signs.
    # Return: Array of {:header, :content} hashes
    def book_collapse(book)
        return nil if book.nil?
        @texts = book.content.to_s.split('#')
        @collapsibles = nil
        
        @texts.each do |text|
            if text =~ /^(.*)/i
                header = $1
                s_idx = header.length+1 # +1 to skip EOL
                e_idx = text.length-1
                content = text[s_idx..e_idx]
                header =~ /^[#\*\?]*(.*)/i
                header = $1
                if !content.nil? 
                    if !content.empty?
                        if content =~ /\A\s*\z/i
                            content = "See Next Section, please!"
                        end
                        len = content.length
                        if header.nil?
                            header = len < 25 ? content.slice(0..len/2-1) + '...' :
                                     content.slice(0..24) + '...' 
                        else
                            if header.empty?
                                header = len < 25 ? content.slice(0..len/2-1) + 
                                         '...' : content.slice(0..24) + '...' 
                            end
                        end
                        @collapsibles ||= Array.new
                        @collapsibles << {
                            header: header.chomp,
                            content: content.chomp
                        }
                     end
                end
            end
        end
        
        return @collapsibles
    end
    
    def gen_title
        @gen = "Leadership as a Service"
    end
    
    def read_binaries(s_file)
        d_obj = nil
        File.open(s_file, "rb") do |f|
            d_obj = f.read
        end
        return d_obj
    end
    
    def s_to_binaries(str)
        return nil if str.nil?
        return nil if str.empty?
        bin_obj = ActiveRecord::Type::Binary.new
        bin_obj.type_cast(str)
    end
    
    def b_to_string(bin)
        return nil if bin.nil?
        str_obj = ActiveRecord::Type::String.new
        str_obj.send(:type_cast, bin)
    end
    
    # Conventions:
    #     Theme     :A line that starts in '###' and ends in EOL
    #     Part      :A line that starts in '##' and ends in EOL
    #     Chapter   :A line starting in '#?' up to EOL
    #     Topic     :A text between '#' and EOL
    #     Subtopic  :A string between '#*' and EOL
    def convert_book
        
        return true if Book.count == 0
        
        @books = Book.all
        
        @books.each do |book|
            philosophy = Philosophy.new(
                language: book[:language],
                author: book[:author],
                theme: book[:theme]
            )
            
            @text = book.content.to_s
            header_bl = true
            @lines = @text.split("\n")
            content_s = ""
            
            @lines.each do |line|
                if line =~ /\A\s*#\s*(.*)\z/i
                    # reinit philosophy object after committing
                    if !header_bl
                        philosophy[:content] = content_s.empty? ? nil : 
                                               s_to_binaries(content_s) 
                        return false if !philosophy.save
                        header_bl = true
                        philosophy.delete
                        philosophy = Philosophy.new(
                            language: book[:language],
                            author: book[:author],
                            theme: book[:theme]
                        )
                    end
                    # part
                    if line =~ /\A\s*###\s*(.*)\z/i
                        philosophy[:part] = $1.chop
                    #theme
                    elsif line =~ /\A\s*##\s*(.*)\z/i
                        philosophy[:theme] = $1.chop
                    #chapter
                    elsif line =~ /\A\s*#\?\s*(.*)\z/i
                        philosophy[:chapter] = $1.chop
                    #topic
                    elsif line =~ /\A\s*#\s*(.*)\z/i
                        philosophy[:topic] = $1.chop
                    #subtopic
                    elsif line =~ /\A\s*#\*\s*(.*)\z/i
                        philosophy[:subtopic] = $1.chop
                    end
                else
                    content_s += line
                    header_bl = false
                end
            end
        end
        
        return true
        
    end
    
    ##########################
    #  Backup file helpers   #
    ##########################
    
    def backup(file)
        backup_wrapper(file)    
    end
    
    # obj: object returned by 'backup' operation
    def recover(file, obj)
        backup_wrapper(file, obj, false)    
    end
    
    # bl: false=recover, true=backup
    # obj: nil=backup, non-nil=recover
    def backup_wrapper(file, obj=nil, bl=true)
        obj ||= DryFileManagement::BackupFile.new(file) if bl
        return nil if obj.nil?
        obj.backup if bl
        obj.recover if !bl
        return obj
    end
    
    def available_source_languages
        @trs = Translation.all
        return nil if @trs.count == 0
        langs = nil
        @trs.each do |tr|
            next if tr[:target_languages].nil?
            next if tr[:target_languages].empty?
            next if tr[:target_languages] =~ /\A\s*\z/
            langs ||= Array.new
            langs << tr[:target_languages].split(':')
        end
        return langs
    end
    
    
    #################################
    #    Translation helpers        #
    #################################
    
    # bl_create: false(unregister) or true(register)
    # model_full_paths: array of full paths to models
    def register_data_models_for_translation(
        obj=nil, bl_create=true, model_full_paths=nil
    )
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.register_data_models_for_translation(bl_create, model_full_paths)
    end
    
    def deserialize(str, obj=nil)
        obj ||= MassTranslation::TranslationSession.new
        obj.deserialize(str)
    end
    
    def get_shortened_language_name(lang, obj=nil)
        obj ||= MassTranslation::TranslationSession.new
        obj.get_shortened_language_name(lang)
    end
    
    # attri: e.g {lengthened: 'French', shortened: 'Fr'}
    def create_languageshort_model(obj=nil, attri=nil)
        obj ||= MassTranslation::TranslationSession.new
        obj.create_languageshort_model('LanguageShort', attri)
    end
    
    def create_model(
        model_name, attributes, obj=nil, code=nil,
        validations="", associations="", callbacks=""
    )
        obj ||= MassTranslation::Tables.new
        obj.create_data_model(
            model_name, attributes, code, validations, associations, callbacks
        )
    end
    
    def destroy_model(model_name, obj=nil)
        obj ||= MassTranslation::Tables.new
        obj.destroy_data_model(model_name)
    end
    
    def destroy_all_models(obj=nil)
        obj ||= MassTranslation::Tables.new
        obj.destroy_all_data_models
    end
    
    # pa_model_name: data model name of parent model (belongs_to argument)
    # ch_model_name: data model name of child model (has_many argument)
    # mig_path: migration folder
    # mig_regex: regular expression used to capture the right migration
    # Return: nil/[full path to migration, code in the migration file]
    def add_foreign_key_to_migration(
        pa_model_name, ch_model_name, mig_path=nil, mig_regex=nil
    )
        obj ||= MassTranslation::Tables.new
        obj.add_foreign_key_to_migration(
            pa_model_name, ch_model_name, mig_path, mig_regex
        )
    end
    
    # Function: Associates a translation model with its translated parent.
    # path: full path to the original model that is to be translated.
    # lang: language into which model is to be translated
    # o_lang: original language.
    # Return: nil/[parent class object, child class object, 
    #              belong_verb argument, have_verb argument]
    def associate_translation_with_original(path, lang, o_lang=nil, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.associate_translation_with_original(path, lang, o_lang)
    end
    
    # N.B: At least one of [code, path] must be non-nil
    def add_association_macro(macro, code, path=nil, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.add_association_macro(macro, code, path)    
    end
    
    def squeeze_net_code_from_model(path, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.squeeze_net_code_from_model(path)
    end
    
    # path: full path to the original model that is to be translated.
    # lang: language into which model is to be translated
    # Return: nil/[class object, net code used to create model]
    def create_translation_data_model(path, lang, obj=nil, code=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.create_translation_data_model(path, lang, code)    
    end
    
    # attributes = {
    #     meta: @metadata (string), # serialize as a hash
    #     o_data: original text(string), 
    #     tr_data: translated text(string)
    # }
    def create_translation_session_model(model_name, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.create_translation_session_model(model_name)
    end
    
    # it uses TranslationSession model and @metadata intel to store
    # the data until whole model(row in Translation model) is translated.
    # payload = {to_translate: '', translated: '', meta: @metadata}
    # @metadata = {
    #     o_language: string # original language
    #     tr_language: string # translation language
    #     row_index: int # index used to get the row entry in proxy_model
    #     column_name: '' # current attribute in the given row
    #     phrase_index: int # index of current phrase given an array of phrases
    # }
    # Assumptions:
    #     There exists a TranslationSession data model whose attributes are
    #     attributes = {
    #         meta: @metadata (text), # serialize as a hash 
    #         o_data: original text(string), 
    #         tr_data: translated text(string)
    #     }
    #     Its name is "TranslationSession" + short form of language into
    #     which model is being translated.
    # Return: nil/TranslationSession class, stored hash]
    def store_translation_session(payload, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.store_translation_session(payload)
    end
    
    # tr_language: if nil, then delete all translation sessions
    def delete_translation_session(tr_language=nil, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.delete_translation_session(tr_language)
    end
    
    # Function: associate models.
    # hash = { parent: #full path, child: #full path, 
    #   have: #has_many, belong: #belongs_to }
    # Return: nil/
    #         [belong_verb argument, have_verb argument, 
    #          parent class object, child class object]
    def associate(hash, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.associate(hash)
    end
    
    # Return: nil/[parent class object, child class object]
    def associates?(class_name1, class_name2, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.associates?(class_name1, class_name2)
    end
    
    # Function: Registers a model with Translation
    # return: [valid :id, child_name] on success,
    #         nil on failure
    def register_for_translation(model_name, model_lang=nil, bl_create=true, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.register_for_translation(model_name, model_lang, bl_create)
    end
    
    # from: original language.
    # into: target language.
    # payload = {to_translate: '', translated: ''}
    # session_inst: session instance in case of loop.
    # Return: [payload-like hash half-full on success:nil on failure:
    #         empty hash on completion:0 on db table completion, session object instance]
    #
    def translate_model(
        from, into, payload = {}, obj_tr=nil, session=nil
    )
        session ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        data = session.translate(from, into, payload, obj_tr)
        return nil if data.nil?
        [data, session]
    end
    
    # from: original language.
    # into: target language.
    # block: code block which will be given
    #        this hash: {to_translate: '', translated: ''}
    #        with :to_translate filled with data to translate.
    #        Store the translated data in :translated.
    #        Your code block will receive an empty hash as an indication
    #        of end of db table entry (row). It should returned the hash
    #        passed to it after needed modification of contents.
    # Return: nil/0
    def translate_db_table(from, into, &block)
        @code_block = block
            
        session_inst = nil
        code = nil
        hash = {}
        
        while code != 0            
            ret = translate_model(from, into, hash, nil, session_inst)
            return nil if ret.nil?
            hash = ret[0]
            session_inst = ret[1]
            return nil if session_inst.nil?
            return nil if hash.nil?
            code = ret[0]
            return 0 if code == 0 
            if hash != {} 
                hash = @code_block.call(hash) unless @code_block.nil?
                debug_write("Data: #{hash}", false)
            end
        end
        
        return 0
    end
    
    def get_model_class_name(file, code=nil, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.get_model_class_name(file, code)
    end
    
    def parse_model_name(model_name, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.parse_model_name(model_name)
    end
    
    def pluralized_table_name(path_to_model, obj=nil)
        obj ||= MassTranslation::TranslationSession.new
        class_name = obj.get_model_class_name(path_to_model)
        db_table_name = obj.parse_model_name(class_name)
        return nil if !DryFileManagement::FileDryMgr.valid_string?(db_table_name)
        db_table_name
    end
    
    # obj: instance of child model
    # foreign_key: id referring to its father model.
    #              Its format is: downcased_singularized_father_name + "_id"
    #              E.g translation_id (if child of Translation model)
    def has_foreign_key?(obj, foreign_key, o=nil)
        o ||= MassTranslation::TranslationSession.new
        o.has_foreign_key?(obj, foreign_key)
    end
    
    # child_table_name: pluralized db table name, the 'has_many'-like argument.
    # parent_table_name: pluralized db table name, the 'belongs_to'-like argument.
    def add_foreign_key_to_model(child_table_name, parent_table_name, obj=nil)
        obj ||= MassTranslation::TranslationSession.new
        obj.add_foreign_key(child_table_name, parent_table_name)
    end
    
    def valid_string?(str, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.send(:valid_string?, str)
    end
    
    def debug_write(str, bl=true, obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.send(:debug_write, str, bl)
    end
    
    def debug_delete(obj=nil)
        obj ||= MassTranslation::TranslationSession.new(
            MassTranslation::Tables.new
        )
        obj.send(:debug_delete)
    end
    
    # hash = { pattern:, replacement:, all?: }
    # Basic support: find a pattern and replace it
    # rev_seq?: if both 'hash' and 'block' are defined
    #           the operations sequence defaults to:
    #           replacement using 'hash' data, then application of 'block'.
    #           To reverse this behavior, fix 'rev_seq?' to true
    # Note: Data is handed to your block as binaries. This allows us to handle
    #       files of different types of data without making unnecessary assumptions.
    
    # This methods wraps up the 'FileDryMgr' functionality
    # Return: FileDryMgr object
    def handle_file_data(file, hash={}, rev_seq=false)
        o_dry_file = DryFileManagement::FileDryMgr.new(file, hash, rev_seq)
    end
    
    def handle_file(file, hash={}, rev_seq=false, &block)
        o_dry_file = DryFileManagement::FileDryMgr.new(file, hash, rev_seq)
        o_dry_file.handle_file_data(&block)
    end
    
    ######################
    #    LaaszenModel    #
    ######################
    
    # attributes: hash whose keys are column names and whose values are type
    #             of column.
    #             N.B: if serialization is needed (for 'text' types) give the type
    #             in the format "type:serialize:type_of_object". E.g text:serialize:Hash
    def define_data_model(
            model_name, attributes, code=nil,
            validations="", associations="", 
            callbacks="", others="", 
            bl_ordinary=true, bl_dynamic=false, lang=nil, obj=nil
        )
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.define_data_model(
            model_name, attributes, code, validations, 
            associations, callbacks, others, lang
        )
    end
    
    def delete_data_model(path=nil, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.delete_data_model(path)
    end
    
    def delete_dynamic_data_model(model_name=nil, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.delete_dynamic_data_model(model_name)
    end
    
    def undefine_data_model(file=nil, obj)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.undefine_data_model(file)
    end
    
    def make_paragraphs(text, bl_reverse=false, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.make_paragraphs(text, bl_reverse)
    end
    
    # N.B: db table is retrieved by call its 'all' method.
    #      Then, an array made of th serialization of each table row
    #      is constituted. The array is assigned to :object column of
    #      the LaaszenSurrogateMother db table.
    # Return: nil/LaaszenSurrogateMother object created.
    def inseminate_surrogate(model_name, model_lang, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.inseminate_surrogate(model_name, model_lang)
    end
    
    def get_db_table_from_surrogate(model_name,language, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.get_db_table_from_surrogate(model_name, language)
    end
    
    def laaszen_translate(from, into, payload={}, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.translate(from, into, payload)
    end
    
    def get_db_table_names(directory=nil, obj=nil) 
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.get_db_table_names(directory)
    end
    
    def get_rows_ids(current_db_table_name, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.get_rows_ids(current_db_table_name)
    end
    
    def get_columns(current_db_table_name, current_row_id, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.get_columns(current_db_table_name, current_row_id)    
    end
    
    def get_phrases(current_db_table_name, current_row_id, current_column, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.get_phrases(
            current_db_table_name, current_row_id, current_column
        )
    end
    
    def load_metadata(into_language, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.load_metadata(into_language)
    end
    
    def manage_graph_state(into_language, metadata, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.manage_graph_state(into_language, metadata)
    end
    
    def init_translation_session(into_language, db_table_name, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.init_translation_session(into_language, db_table_name)
    end
    
    def store_translation_session(into_language, payload, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.store_translation_session(into_language, payload)
    end
    
    def load_translation_from_tr_session(into_language, db_table_name, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.load_translation_from_tr_session(into_language, db_table_name)
    end
    
    def persist_translation(into_language, db_table_name=nil, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.persist_translation(into_language, db_table_name)
    end
    
    def translate_and_persist(from_language, into_language, data={}, obj=nil)
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.translate_and_persist(from_language, into_language, data)
    end
    
    def edit_model_translation(
        into_language, db_table_name, tr_payload={}, obj=nil
    )
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        laaszen_model.edit_model_translation(
            into_language, db_table_name, tr_payload
        )
    end
    
    def load_translated_payload_from_tr_session(
            into_language, db_table_name, 
            index_metadata={}, bl_load_class = false, 
            stop_value=nil, obj=nil, &functor
        )
        ret = nil
        laaszen_model = obj
        laaszen_model ||= LaaszenModel::DataModel.new(::Rails.root)
        if functor.nil?
            ret = laaszen_model.load_translated_payload_from_tr_session(
                into_language, db_table_name, index_metadata, 
                bl_load_class, stop_value
            )                  
        else
            ret = laaszen_model.load_translated_payload_from_tr_session(
                      into_language, db_table_name, index_metadata, 
                      bl_load_class, stop_value
                  ) do |tr|
                      functor.call(tr) 
                  end 
        end
        
        return ret  
    end
    
    ######################
    #    SiteLanguage    #
    ######################
    
    def get_site_cache
        LaaszenModel::SiteLanguage.get_site_cache
    end
    
    def set_default_language(lang=nil)
        LaaszenModel::SiteLanguage.set_default_language(lang)
    end
    
    def get_default_language
        LaaszenModel::SiteLanguage.get_default_language
    end
    
    def set_active_language(lang=nil)
        LaaszenModel::SiteLanguage.set_active_language(lang)
    end
    
    def get_active_language
        LaaszenModel::SiteLanguage.get_active_language
    end
    
    def set_supported_languages(lang)
        LaaszenModel::SiteLanguage.set_supported_languages(lang)
    end
    
    def get_supported_languages
        LaaszenModel::SiteLanguage.get_supported_languages
    end
    
    def sentence(str, obj=nil)
        return str
        obj ||= LaaszenModel::SiteLanguage.new
        ck_str = obj.get_sentence_from_cache(str)
        return ck_str unless ck_str.nil?
        
        tr_str = obj.sentence(str)
        return tr_str
    end
    
    ######################
    #    HtmlRotator     #
    ######################
    
    def define_html_rotator(array, partial_full_path, obj=nil)
        r_obj = obj
        r_obj ||= HtmlRotator::Rotator.new
        r_obj.define_html_rotator(array, partial_full_path)
    end
    
    ######################
    #    HtmlDropDown    #
    ######################
    
    def define_html_drop_down_class(
        hash, max_menus, partial_full_path, orientation='down', obj=nil
    )
        dd_obj = obj
        dd_obj ||= HtmlDropDown::DropDown.new
        dd_obj.define_html_drop_down_class(
            hash, max_menus, partial_full_path, orientation
        )
    end
    
    def site_language_drop_down
        active = LaaszenModel::SiteLanguage.get_active_language
        supported = LaaszenModel::SiteLanguage.get_supported_languages
        
        hash = {}
        key = "sentence('#{active}')"
        values = []
        
        supported.each do |l|
            values << "sentence('#{l}')"
        end
        
        hash[key] = values
        
        options = {
            dl_opts: "class: 'dropdown'",
            dt_opts: "class: 'ddheader'",
            dd_opts: "class: 'ddcontent'",
            div_opts: "'data-theme' => 'c', class: 'nav_links centered lang_div'"
        }
        
        return hash, options, active
    end
end

