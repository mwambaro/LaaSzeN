
require 'dry_file_mgr'

module LaaszenModel
    class SiteLanguage
        attr_reader :data_model
        def initialize(active_lang=nil)
            begin
                @errors = String.new
                @data_model = DataModel.new(::Rails.root)
                @default_language = SiteLanguage.get_default_language
                @active_language = SiteLanguage.get_active_language
            rescue => err
                handle_error('initialize', err)
            end
        end
        
        def SiteLanguage.set_from_route(route)
            return nil unless DryFileManagement::FileDryMgr.valid_string?(route) 
            count = ActiveLanguage.count
            
            if count == 0
                begin
                    a = ActiveLanguage.create!({from_route: route})
                    return route unless a.nil?
                rescue => err
                    return nil
                end
            end
            
            a_lang = ActiveLanguage.first
            return nil if a_lang.nil?
            
            hash = a_lang.attributes
            hash.merge!(from_route: route)
            
            return nil unless a_lang.update_attributes(hash)
            
            return route
        end
        
        def SiteLanguage.get_site_cache
            Worldcitizen::Application.config.action_controller.cache_store
        end
        
        def SiteLanguage.get_from_route
            a_lang = ActiveLanguage.first
            return nil if a_lang.nil?
            
            return a_lang.from_route
        end
        
        def SiteLanguage.set_supported_languages(lang)
            lang = lang.nil? ? 'English' : lang
            count = ActiveLanguage.count
            
            s_lg = nil
            
            if count == 0
                return nil unless SiteLanguage.set_default_language(lang)
            else
                a_lang = ActiveLanguage.first
                return nil if a_lang.nil?
                
                # is 'lang' already persisted ?
                m = a_lang.supported.split('#')
                m.each do |l|
                    return m if l.match(/\A#{lang}\z/i)
                end
                
                hash = a_lang.attributes
                hash['supported'] = "#{a_lang.supported}" + '#' + "#{lang}"
            
                return nil unless a_lang.update_attributes(hash)
            end
            
            s_lg_str = ActiveLanguage.first.supported
            return nil unless DryFileManagement::FileDryMgr.valid_string?(s_lg_str)
            
            return s_lg_str.split('#')
        end
        
        def SiteLanguage.get_supported_languages
            count = ActiveLanguage.count
            
            if count == 0
                return SiteLanguage.set_supported_languages(nil)
            end
            
            s_lg_str = ActiveLanguage.first.supported
            return nil unless DryFileManagement::FileDryMgr.valid_string?(s_lg_str)
            
            langs = nil
            obj = nil
            
            s_lg_str.split('#').each do |l|
                langs ||= Array.new
                obj ||= LaaszenModel::SiteLanguage.new
                langs << obj.sentence(l)
            end
            
            return langs.sort
        end
        
        def SiteLanguage.reset_site_language_cookies(lang)
            return nil unless DryFileManagement::FileDryMgr.valid_string?(lang)
            
            a = ActiveLanguage.find_by({active: lang})
            cookies.delete :site_sentence if a.nil?
            
            return lang
        end
        
        def SiteLanguage.set_active_language(lang)
            lang = lang.nil? ? 'English' : lang
            count = ActiveLanguage.count
            
            l_obj = LaaszenModel::DataModel.new(::Rails.root)
            
            old_lang = nil
            aa_lg = ActiveLanguage.find_by({active: lang})
            old_lang = lang unless aa_lg.nil?
            
            if count == 0
                re = SiteLanguage.set_default_language(lang)
                if re.nil?
                    return l_obj.error_message(
                        "set_active_language:set_default_language"
                    )
                end
            end
            
            a_lang = ActiveLanguage.first
            if a_lang.nil?
                return l_obj.error_message(
                    "set_active_language:ActiveLanguage.first"
                )
            end
            
            hash = a_lang.attributes
            hash.merge!(active: lang)
            
            re = a_lang.update_attributes(hash)
            if re.nil?
                return l_obj.error_message(
                    "set_active_language:a_lang.update_attributes"
                )
            end
            
            if old_lang != lang
                SiteLanguage.get_site_cache.reset_site_language_cache
                SiteLanguage.get_site_cache.set_active_language(lang)
            end
            
            return lang
        end
        
        def SiteLanguage.get_active_language
            a_lg = nil
            a_lang = ActiveLanguage.first
            if a_lang.nil?
                SiteLanguage.set_active_language(nil)
                a_lang = ActiveLanguage.first
                return nil if a_lang.nil?
                a_lg = a_lang.active
            else 
                a_lg = a_lang.active
            end
            
            return a_lg  
        end
        
        def SiteLanguage.set_default_language(lang)
            lang = lang.nil? ? 'English' : lang
            count = ActiveLanguage.count
            
            if count == 0
                begin
                    ActiveLanguage.create!({
                        language: lang, 
                        active: lang, 
                        default: lang,
                        supported: lang
                    })
                rescue => err
                    return nil
                end
            end
            
            d_flt = ActiveLanguage.first.default
            d_flt = d_flt.nil? ? lang : d_flt
            
            return d_flt
        end
        
        def SiteLanguage.get_default_language
            d_flt = nil
            a_lang = ActiveLanguage.first
            if a_lang.nil?
                d_flt = SiteLanguage.set_default_language(nil)
            else 
                d_flt = a_lang.default
            end
            
            return d_flt
        end
        
        def fill_site_language_cache(surrogate_db)
            return nil if surrogate_db.nil?
            
            cache = nil
            
            surrogate_db.all.each do |r|
                begin
                    o_str = r.o_sentence
                    tr_str = r.tr_sentence
                    if SiteLanguage.get_site_cache.get_active_language.nil?
                        SiteLanguage.get_site_cache.set_active_language(
                            @active_language
                        )
                    end
                    re = SiteLanguage.get_site_cache.set_cache_sentence(o_str, tr_str)
                    if re.nil?
                        return @data_model.error_message(
                            'fill_site_language_cache:set_cache_sentence(): failed.'
                        )
                    end    
                rescue => err
                    return handle_error('fill_site_language_cache', err)
                end
            end
            
            return surrogate_db
        end
        
        def get_sentence_from_cache(str)
            return nil unless valid_string?(str)
            
            tr_str = nil
            
            begin
                tr_str = SiteLanguage.get_site_cache.get_cache_sentence(str)   
            rescue => err
                handle_error('sentence:get_cache_sentence', err)
            end
            
            # debug_write("'#{tr_str}' found in SiteCache.") unless tr_str.nil?
            
            return tr_str
        end
        
        def sentence(str)
            return str unless valid_string?(str)
            return str unless valid_string?(@active_language)
            return str if @data_model.nil?
            
            re = nil
            begin
                hash = {
                    language: @default_language, 
                    o_sentence: str,
                    tr_sentence: str
                }
                
                lg = Lang.find_by(hash)
                if lg.nil?
                    begin
                        hash[:o_language] =  @default_language
                        hash[:tr_language] = @active_language
                        Lang.create!(hash)
                    rescue => err
                        handle_error('sentence', err)
                        return str
                    end
                end
                
                re = @data_model.inseminate_surrogate('Lang', @default_language)
                if re.nil?
                    @data_model.error_message(
                        'sentence:inseminate_surrogate(): failed.'
                    )
                    return str
                end
            
                db = @data_model.get_db_table_from_surrogate('Lang', @active_language)
                if db.nil?
                    @data_model.error_message(
                        'sentence:get_db_table_from_surrogate(): failed.'
                    )
                    return str
                end
                
                re = fill_site_language_cache(db)
                if re.nil?
                    @data_model.error_message(
                        'sentence:fill_site_language_cache(): failed.'
                    )
                end
            
                re = db.find_by({language: @active_language, o_sentence: str})
            rescue => err
                handle_error('sentence', err)
                return str   
            end
            
            return str if re.nil?
            
            return re[:tr_sentence]
        end
        
        def data_model
            @data_model
        end
        
        def get_debug_messages
            @errors
        end
        
        def handle_error(method, err_obj, bl_log=true)
            return nil unless valid_string?(method)
            return nil if err_obj.nil?
            return nil unless err_obj.respond_to?(:message)
            
            message = "#{self.class.to_s}::#{method}():" +
                      " #{err_obj.message}"
            @errors += "\r\n  #{message}"
            debug_write("#{message}", bl_log)
            return nil
        end
        
        private
        
        def string_valid?(str)
            DryFileManagement::FileDryMgr.valid_string?(str)
        end
        
        def valid_string?(str)
            DryFileManagement::FileDryMgr.valid_string?(str)
        end
        
        def hash_valid?(h, bl_values=true)
            DryFileManagement::FileDryMgr.valid_hash?(h, bl_values)
        end
        
        def valid_hash?(h, bl_values=true)
            DryFileManagement::FileDryMgr.valid_hash?(h, bl_values)
        end
        
        def valid_array?(a)
            DryFileManagement::FileDryMgr.valid_array?(a)
        end
        
        def array_valid?(a)
            DryFileManagement::FileDryMgr.valid_array?(a)
        end
        
        def valid_file?(f)
            DryFileManagement::FileDryMgr.valid_file?(f)
        end
        
        def file_valid?(f)
            DryFileManagement::FileDryMgr.valid_file?(f)
        end
        
        def b_to_string(bin)
            return nil if bin.nil?
            str_obj = ActiveRecord::Type::String.new
            str_obj.send(:type_cast, bin)
        end
        
        def debug_write(str, bl=true)
            return nil if ENV['RAILS_ENV'] == 'production'
            return nil unless valid_string?(str)
            if bl
                file = File.join(::Rails.root, 'log', 'log')
                data = "\r\n#{Time.now}: #{str}"
                File.open(file, "ab"){|f| f.write(data)}
                file
            end
        end
        
        def debug_delete
            return nil if ENV['RAILS_ENV'] == 'production'
            file = File.join(::Rails.root, 'log', 'log')
            return nil unless valid_file?(file)
            File.delete(file)
        end
    end
    
    class DataModel
        attr_reader :file
        def initialize(root=nil)
            @model_name = nil
            @attribs = nil
            @dynamic_attribs = nil
            @code = nil
            @validations = nil
            @associations = nil
            @callbacks = nil
            @others = nil
            @bl_ordinary = nil
            @bl_dynamic = nil
            @max_paragraphs = 1
            @lang = nil
            @file = nil
            @tb_obj = nil
            @d_models = nil
            @root = root.nil? ? nil : root.to_s
            @errors = String.new
            @bl_persisting = false
            @tr_db_table_as_array = nil
            @columns = nil
            @tr_klass = nil
            @row = nil
            @row_data = nil
            @tr_session_row = nil
        end
        
        def get_debug_messages
            @errors
        end
        
        def error_message(message)
            if ::Rails.env =~ /\Aproduction\z/i
                return nil
            else
                debug_write("#{self.class.to_s}::#{message}")
                return nil
            end
            
            return nil
        end
        
        def handle_error(method, err_obj, bl_log=true)
            return nil unless valid_string?(method)
            return nil if err_obj.nil?
            return nil unless err_obj.respond_to?(:message)
            
            message = "#{self.class.to_s}::#{method}():" +
                      " #{err_obj.message}"
            @errors += "\r\n  #{message}"
            debug_write("#{message}", bl_log)
            return nil
        end
        
        ## ALGO-Compatible ##
        
        # active_meta_data: {
        #    db_table_name:
        #    row_id:
        #    column_name:
        #    db_table_as_array_idx:
        #    column_index: 
        #    payload_index:
        #    db_array_length:
        #    column_length:
        #    payload_length:
        #    bl_translatable:
        #    mdigest: 
        # }
        
        def proof_read_translation(into_language, db_table_name, tr_payload={})
            return
        end
        
        # into_language: the language into which model was translated.
        # db_table_name: name of the model whose translation to edit.
        # tr_payload: Initialize it to {} and then be passing the returned 
        #             version of it until the function returns 0.
        #             tr_payload is defined as 
        # tr_payload = {
        #     payload: ,
        #     index_metadata: 
        # }
        # NB: You should not touch the 'index_metadata' part of tr_payload!!
        # Return: nil on failure/tr_payload/0 on completion
        def edit_model_translation(into_language, db_table_name, tr_payload={})
            return nil unless valid_string?(into_language)
            return nil unless valid_string?(db_table_name)
            
            tr_payload = {} if tr_payload.nil?
            
            index_metadata = nil
            payload = nil
            digest = nil
            
            if tr_payload.empty?
                index_metadata = {}
                payload = {}
            else
                index_metadata = tr_payload[:index_metadata]
                payload = tr_payload[:payload]
                digest = tr_payload[:digest]
            end
            
            if payload_has_valid_translated?(payload)
                re = store_translation_session(into_language, payload)
                if re.nil? 
                    return error_message(
                        "edit_model_translation:" +
                        "store_translation_session(): failed."
                    )
                end
            end
            
            re = load_translated_payload_from_tr_session(
                into_language, db_table_name, index_metadata, false
            )
            if re.nil?                
                return error_message(
                    'edit_model_translation:' +
                    'load_translated_payload_from_tr_session(): failed'
                )
            end
            
            if re.class.to_s =~ /\Ahash\z/i
                tr_payload = re
                return tr_payload
            elsif re == 0
                # do sth like persisting the translation in surrogate mother
                return 0
            else
                return nil
            end
            
            return 0
        end
        
        def translate_and_persist(from_language, into_language, data={})
            return nil unless valid_string?(into_language)
            
            @bl_persisting = true
            if payload_has_valid_translated?(data)
                re = store_translation_session(into_language, data)
                if re.nil? 
                    return error_message("store_translation_session(): failed.")
                end
            end
            
            ret = translate(from_language, into_language, data)
            if ret.nil? 
                return error_message("translate(): failed.")
            end
            
            unless ret.class.to_s =~ /\Ahash\z/i || ret.nil?
                re = persist_translation(into_language)
                if re.nil?
                    return error_message("persist_translation(): failed.")
                end
            end
            
            return ret
        end
        
        def translate(from_language, into_language, data={})
            return nil unless valid_string?(from_language)
            return nil unless valid_string?(into_language)      
            
            metadata = load_metadata(into_language)
            return nil if metadata.nil?
            
            ret_value = manage_graph_state(into_language, metadata)
            return nil if ret_value.nil?
            
            if ret_value.class.to_s =~ /array/i
                payload, metadata = ret_value
                           
                re = store_metadata(into_language, metadata)
                return nil if re.nil?
                
                return payload  
            end
            
            return 0
        end
        
        def load_metadata(into_language)
            return nil unless valid_string?(into_language)
            meta = nil
            ret  = nil
       
            begin
                ret = MetaInfo.find_by!({language: into_language})
            rescue => err
                handle_error('load_metadata', err, false)
            end
            
            begin
            
            if ret.nil?
                meta = init_graph
            else
                metadata = ret.metadata
                meta = {
                    vertex_array: YAML::load(metadata[:vertex_array]),
                    edge_array: YAML::load(metadata[:edge_array])
                }
            end
            
            rescue => err
                return handle_error('load_metadata', err, false)
            end
               
            return meta
        end
        
        def init_graph
            
            metadata = {
                vertex_array: [Array.new, Array.new, Array.new, Array.new],
                edge_array: [nil, nil, nil]
            } 
            
            db_table_names = get_db_table_names
            return metadata if db_table_names.nil? || db_table_names.empty?
            len = db_table_names.length
            db_table_name = db_table_names[len-1]
            metadata[:vertex_array][0] = db_table_names
            metadata[:edge_array][0] = db_table_name
            
            rows_ids = get_rows_ids(db_table_name)
            return metadata if rows_ids.nil? || rows_ids.empty?
            len = rows_ids.length
            row_id = rows_ids[len-1]
            metadata[:vertex_array][1] = rows_ids
            metadata[:edge_array][1] = row_id
            
            columns = get_columns(db_table_name, row_id)
            return metadata if columns.nil? || columns.empty?
            len = columns.length
            column_name = columns[len-1]
            metadata[:vertex_array][2] = columns
            metadata[:edge_array][2] = column_name
            
            phrases = []
            metadata[:vertex_array][3] = phrases    
           
            return metadata
        end
        
        def store_metadata(into_language, metadata)
            return nil unless valid_string?(into_language)
            return nil if metadata.nil?
            
            meta = {
                vertex_array: YAML::dump(metadata[:vertex_array]),
                edge_array: YAML::dump(metadata[:edge_array])
            }
     
            hash = {
                language: into_language,
                metadata: meta
            }
            
            m_info = nil
            
            begin
                m_info = MetaInfo.find_by({language: into_language})
                if m_info.nil?
                    m_info = MetaInfo.create!(hash)  
                    return nil if m_info.nil?     
                else
                    m_info = m_info.update_attributes(hash)
                    return nil if m_info.nil?
                end
            rescue => err
                return handle_error('store_metadata', err, false)
            end
            
            return m_info  
        end
        
        def get_db_table_names(directory=nil)               
            excls = [
                'translation_session.rb',
                'laaszen_surrogate_mother.rb',
                'translation.rb',
                'meta_info.rb',
                'active_language.rb',
                'laaszen_task.rb',
                'tr_payload.rb',
                'tr_session.rb',
                'drop_down_id.rb'
            ]
            
            db_table_names = nil
                
            folder = directory.nil? ? 
                     File.join(::Rails.root, 'app', 'models') : directory
            Dir.entries(folder).each do |e|
                if(
                    e =~ /\A\.|\.\.\z/i || 
                    e =~ /~|\.up\.rb$/i || # backup files
                    File.directory?(File.join(folder, e))
                )
                    next
                end
                    
                bl = false
                excls.each do |ex|
                    if ex =~ /\A#{e}\z/i
                        bl = true
                        break
                    end
                end
                next if bl == true
                    
                file = File.join(folder, e)
                model_name = get_model_class_name(file)
                return nil unless valid_string?(model_name)
                db_table_names ||= Array.new
                db_table_names << model_name
            end
            
            return db_table_names
        end
        
        def get_rows_ids(db_table_name)
            return nil unless valid_string?(db_table_name)
            
            rows_ids = nil
            
            begin
                klass = Object.const_get(db_table_name)
                return nil if klass.nil?
                    
                count = klass.count
                if count > 0
                    all = klass.all
                    all.each do |m|
                        rows_ids ||= Array.new
                        rows_ids << m.id
                    end
                end
            rescue => err
                return handle_error('get_rows_ids', err)
            end
            
           return rows_ids
        end
        
        def get_columns(db_table_name, row_id)
            return nil unless valid_string?(db_table_name)
            return nil if row_id.nil?
            
            columns = nil
            
            begin
                klass = Object.const_get(db_table_name)
                return nil if klass.nil?
                mod = klass.find(row_id)
                return nil if mod.nil?
                columns = get_model_net_attributes(mod)
            rescue => err
                 return handle_error('get_columns', err)
            end          
            
            return columns
        end
        
        def join_paragraphs(ary, bl_reverse=false)
            return nil if ary.nil?
            return ary unless ary.class.to_s =~ /array/i
            return ary if ary.empty?
            
            len = ary.length-1
            text = nil
            
            if bl_reverse == false
                0.upto(len) do |i|
                    if i == 0
                        text = "#{ary[i]}"
                    else
                        text += "\r\n\r\n#{ary[i]}"
                    end
                end
            else
                len.downto(0) do |i|
                    if i == len
                        text = "#{ary[i]}"
                    else
                        text += "\r\n\r\n#{ary[i]}"
                    end
                end
            end
            
            return text
        end
        
        def make_paragraphs(text, bl_reverse=false)
            return nil if text.nil?
    
            par = text
            pars = nil
    
            while m = par.match(/\n\n|\r\n\r\n/)
                unless m.pre_match.nil? || m.pre_match.empty?
                    pars ||= Array.new
                    pars << m.pre_match
                end
                break if m.post_match.nil? || m.post_match.empty?
                par = m.post_match
            end
    
            unless pars.nil?
                pars << par
                if bl_reverse
                    pars = pars.reverse
                end
            end
    
            pars = [par] if pars.nil?
    
            return pars
        end
        
        def get_phrases(db_table_name, row_id, column_name)
            
            return nil unless valid_string?(db_table_name)
            return nil unless valid_string?(column_name)
            return nil if row_id.nil?
            
            paragraphs = nil
            
            begin
                klass = Object.const_get(db_table_name)
                return nil if klass.nil?
                row = klass.find(row_id)
                if row.nil?
                    debug_write(
                        "#{self.class.to_s}::get_phrases:"+
                        "find(#{row_id})"
                    )
                    return nil
                end
                column = row[column_name.to_sym] 
                    
                return [] if column.nil?
                    
                column = column.to_s
                    
                return [] unless valid_string?(column)
                    
                paragraphs = make_paragraphs(column, true)
                if paragraphs.nil?
                    debug_write(
                        "#{self.class.to_s}::get_phrases:"+
                        "split(#{column});length==0"
                    )
                    return nil
                end
            rescue => err
                return handle_error('get_phrases', err)
            end
            
            return paragraphs
        end
        
        # empty the vertices below
        def empty_dependent_vertices(vertex_array, idx)
            unless vertex_array.nil?
                en = vertex_array.length-1
                st = idx+1
            
                st.upto(en){|i| vertex_array[i] = []}
            end
        end
        
        def get_edge_value(vertex_array, idx)
            return nil if vertex_array.nil?
            return nil if idx.nil?
            
            edge = nil
            
            begin
                if !vertex_array[idx].nil? && !vertex_array[idx].empty?
                    len = vertex_array[idx].length
                    edge = vertex_array[idx][len-1]
                end
            rescue => err
                return handle_error('get_edge_value', err, false)
            end
            
            return edge
        end
        
        def manage_graph_state(into_language, metadata)
            return nil unless valid_string?(into_language)
            return nil if metadata.nil?
            
            # active_meta = {
            #    db_table_name:
            #    row_id:
            #    column_name:
            #    db_table_as_array_idx:
            #    column_index: 
            #    payload_index:
            #    db_array_length:
            #    column_length:
            #    payload_length:
            #    bl_translatable:
            #    mdigest: 
            # }
            active_meta = Hash.new
            active_meta = {
                db_table_name: nil,
                row_id: nil,
                column_name: nil,
                db_table_as_array_idx: nil,
                column_index: nil,
                payload_index: nil,
                db_array_length: nil,
                column_length: nil,
                payload_length: nil,
                bl_translatable: false,
                mdigest: nil
            }
            max_paragraphs = @max_paragraphs
            vertex_array = nil
            edge_array = nil
            
            begin
            
            vertex_array = metadata[:vertex_array]
            edge_array = metadata[:edge_array]                       
    
            return 0 if vertex_array[0].nil? || vertex_array[0].empty?
               
            while !vertex_array[0].empty?
                idx_v = edge_array[0]
                active_meta[:db_table_name] = edge_array[0]
                
                if vertex_array[1].nil? || vertex_array[1].empty?
                    vertex_array[1] = get_rows_ids(edge_array[0])
                    edge_array[1] = get_edge_value(vertex_array, 1)
                end
                
                while !vertex_array[1].nil? && !vertex_array[1].empty?
                    idx1_v = edge_array[1]
                    active_meta[:row_id] = edge_array[1]
                    
                    if vertex_array[2].nil? || vertex_array[2].empty?                       
                        vertex_array[2] = get_columns(edge_array[0], edge_array[1])
                        edge_array[2] = get_edge_value(vertex_array, 2)
                    end
                    
                    while !vertex_array[2].nil? && !vertex_array[2].empty?
                        idx2_v = edge_array[2]
                        active_meta[:column_name] = edge_array[2]
                        active_meta[:bl_translatable] = translatable?(
                            active_meta[:db_table_name], edge_array[2]
                        )
                                               
                        ret = handle_column_data(
                            into_language, active_meta, metadata
                        ) 
                        return nil if ret.nil?
                        payload, metadata = ret
                        # DRY translation data
                        dry_py = dry_duplicate_to_translate_loads(into_language, payload)
                        unless dry_py.nil?
                            return manage_graph_state(into_language, metadata)
                        end
                        
                        return payload, metadata
                    end
                    # empty the vertices below
                    empty_dependent_vertices(vertex_array, 1)
                    # delete current edge
                    a = vertex_array[1].delete(idx1_v)
                    break if vertex_array[1].empty?
                    edge_array[1] = get_edge_value(vertex_array, 1)
                end
                if @bl_persisting == true || ::Rails.env =~ /\Aproduction\z/i
                    re = finalize_db_table_translation(into_language, idx_v)
                    if re.nil?
                        return error_message(
                            "manage_graph_state:"+
                            "finalize_db_table_translation: failed."
                        )
                    end
                end
                # empty the vertices below
                empty_dependent_vertices(vertex_array, 0)
                # delete current edge
                a = vertex_array[0].delete(idx_v)
                return 0 if vertex_array[0].empty?
                edge_array[0] = get_edge_value(vertex_array, 0)
            end
            
            rescue => err
                return handle_error('manage_graph_state', err)
            end
    
            return 0
        end
        
        def translatable?(db_table_name, column)
            return false unless valid_string?(column)
            return false unless valid_string?(db_table_name)
            
            db_table_name = db_table_name
            column_name = column
            
            klass = nil
            type = nil
            
            begin
                klass = Object.const_get(db_table_name)
                row_obj = klass.new
                type = attribute_type(row_obj, column_name)
            rescue => err
                handle_error('translatable?', err)
                return false
            end
            
            return false if type.nil?
            
            if(
                type =~ /\Astring|text|binary\z/i && 
                !(column_name =~ /\Adata\z/i && type =~ /\Abinary\z/i) &&
                !(column_name =~ /\Ao_sentence|o_language|language\z/i)
            )
                return true
            else
                return false
            end
            
            return false
        end
        
        def handle_column_data(into_language, active_meta, metadata) 
            return nil unless valid_string?(into_language)
            return nil if active_meta.nil?
            return nil if metadata.nil?
            
            vertex_array = metadata[:vertex_array]
            edge_array = metadata[:edge_array]
            
            db_table_name = active_meta[:db_table_name]
            row_id = active_meta[:row_id]
            column_name = active_meta[:column_name]
            bl_translatable = active_meta[:bl_translatable]
            
            klass = nil
            type = nil
            
            begin
                klass = Object.const_get(db_table_name)
            rescue => err
                return handle_error('handle_column_data', err)
            end
            
            begin
            
            payload_array = nil 
                        
            if bl_translatable
                if vertex_array[3].nil? || vertex_array[3].empty?
                    vertex_array[3] = get_phrases(
                        db_table_name, row_id, column_name    
                    )
                end
                                
                while !vertex_array[3].nil? && !vertex_array[3].empty?
                    current_phrase = vertex_array[3].pop(@max_paragraphs)
                    # debug_write("\r\n#{current_phrase}\r\n")
                    # return after storing metadata
                    if vertex_array[3].empty?
                        # empty the vertices below
                        empty_dependent_vertices(vertex_array, 2)
                        # delete current edge
                        vertex_array[2].delete(column_name)
                        if vertex_array[2].empty?
                            # empty the vertices below
                            empty_dependent_vertices(vertex_array, 1)
                            # delete current edge
                            vertex_array[1].delete(row_id)
                            if vertex_array[1].empty?
                                # empty the vertices below
                                empty_dependent_vertices(vertex_array, 0)
                                if(
                                    @bl_persisting == true || 
                                    ::Rails.env =~ /\Aproduction\z/i
                                )
                                    re = finalize_db_table_translation(
                                        into_language, db_table_name
                                    )
                                    if re.nil?
                                        return error_message(
                                            "handle_column_data:"+
                                            "finalize_db_table_translation:"+
                                            " failed."
                                        )
                                    end
                                end
                                # delete current edge
                                vertex_array[0].delete(db_table_name)
                                unless vertex_array[0].empty?
                                    edge_array[0] = get_edge_value(vertex_array, 0)
                                end
                            else
                                edge_array[1] = get_edge_value(vertex_array, 1)
                            end
                        else
                            edge_array[2] = get_edge_value(vertex_array, 2)
                        end  
                    end
                            
                    metadata[:vertex_array] = vertex_array
                    metadata[:edge_array] = edge_array
                    
                    data = join_paragraphs(current_phrase, true)
                    
                    payload = {
                        to_translate: data,
                        translated: '',
                        active_meta: active_meta
                    }
                    return payload, metadata
                end
            else
                vertex_array[3] = []
                vertex_array[2].delete(column_name)
                if vertex_array[2].empty?
                    vertex_array[1].delete(row_id)
                    if vertex_array[1].empty?
                        if(
                            @bl_persisting == true || 
                            ::Rails.env =~ /\Aproduction\z/i
                        )
                            re = finalize_db_table_translation(
                                into_language, db_table_name
                            )
                            if re.nil?
                                return error_message(
                                    "handle_column_data:"+
                                    "finalize_db_table_translation:"+
                                    " failed."
                                )
                            end
                        end
                        vertex_array[0].delete(db_table_name)
                        unless vertex_array[0].empty?
                            edge_array[0] = get_edge_value(vertex_array, 0)
                        end
                    else
                        edge_array[1] = get_edge_value(vertex_array, 1)
                    end
                else
                    edge_array[2] = get_edge_value(vertex_array, 2)
                end 
                
                metadata[:vertex_array] = vertex_array
                metadata[:edge_array] = edge_array
                
                data = nil
                row_obj = nil
                if column_name =~ /\Alanguage|tr_language\z/
                    data = into_language
                else
                    row_obj = klass.find(row_id) unless klass.nil?
                    unless column_name.nil?
                        data = row_obj[column_name.to_sym] unless row_obj.nil?
                    end
                end
                
                payload = {
                    to_translate: data,
                    translated: data,
                    active_meta: active_meta
                }
            end
            
            rescue => err
                return handle_error('handle_column_data', err)
            end
            
            return payload, metadata
        end
        
        def commit_payload_to_tr_session(into_language, payload)
            return nil unless valid_string?(into_language)
            return nil unless payload_has_valid_translated?(payload)
            
            tr_db_table_as_array, tr_klass, tr_s_row = nil, nil, nil
            
            begin
                db_table_name = payload[:active_meta][:db_table_name]
                row_id = payload[:active_meta][:row_id]
                
                re = get_db_table_as_array_from_tr_session(
                        into_language, db_table_name
                )
                if re.nil?
                    return nil
                end
                        
                tr_db_table_as_array, tr_klass, tr_s_row = re
                
                len = tr_db_table_as_array.length
                bl_committed = false
            
                0.upto(len-1) do |db_idx|
                    row = YAML::load(tr_db_table_as_array[db_idx])
                    if row_id == row.id.to_i
                        columns = get_columns(db_table_name, row_id)
                        if columns.nil?
                            return error_message(
                                'commit_payload_to_tr_session:' +
                                'get_columns(): failed.'
                            )
                        end
                        
                        payload[:active_meta][:db_array_length] = len
                        payload[:active_meta][:db_table_as_array_idx] = db_idx
                        payload[:active_meta][:column_length] = columns.length
                        
                        c_col = payload[:active_meta][:column_name]
                        if c_col.nil?
                            raise "#{self.class.to_s}::commit_payload_to"+
                                  "_tr_session(): c_col cannot be nil."
                        end
                        
                        column_index = columns.find_index(c_col)
                        if column_index.nil?
                            return error_message(
                                'commit_payload_to_tr_session:' +
                                'columns.find_index(): failed.'
                            )
                        end
                        
                        payload[:active_meta][:column_index] = column_index
                        bl_translatable = payload[:active_meta][:bl_translatable]
                        
                        if bl_translatable.nil?
                            bl_translatable = translatable?(db_table_name, c_col)
                            payload[:active_meta][:bl_translatable] = bl_translatable
                        end
                        
                        if bl_translatable
                            row_data = nil
                            
                            unless row[c_col.to_sym].nil?
                                row_data = YAML::load(row[c_col.to_sym])
                            end
                            
                            if row_data.nil?
                                row_data = Array.new
                            end
                            
                            payload[:active_meta][:payload_length] = row_data.length+1
                            payload[:active_meta][:payload_index] = row_data.length
                            
                            row_data << YAML::dump(payload)
                            row[c_col.to_sym] = YAML::dump(row_data)
                        else
                             row[c_col.to_sym] = payload[:to_translate]
                        end
                        
                        tr_db_table_as_array[db_idx] = YAML::dump(row)
                        bl_committed = true
                        break
                    end
                end
                
                unless bl_committed
                    raise "#{self.class.to_s}::commit_payload_to_tr_session: " +
                          "Exception => Fatal logical error: row ids mismatch."
                end
                
                tr_s_row.object = tr_db_table_as_array
                re = tr_s_row.update_attributes(tr_s_row.attributes)
                if re.nil?
                    return error_message(
                        'commit_payload_to_tr_session:' +
                        'tr_db_row.update_attributes(): failed.'
                    )
                end
            rescue => err
                return handle_error(
                    'commit_payload_to_tr_session', err
                )
            end
            
            if(
                tr_db_table_as_array.nil? || tr_klass.nil? || tr_s_row.nil?
            )
                return error_message(
                    'commit_payload_to_tr_session:' +
                    'sth wicked happened. About to return garbage!!'
                )
            end
            
            return tr_db_table_as_array, tr_klass, tr_s_row
        end
        
        def store_translation_session(into_language, payload)
            return nil unless valid_string?(into_language)
            return nil unless payload_has_valid_translated?(payload)
            
            active_meta = nil
            db_table_name = nil
            
            begin
                active_meta = payload[:active_meta]
                db_table_name = active_meta[:db_table_name]
            rescue => err
                return handle_error('store_translation_session', err)
            end
    
            tr_db_table_as_array, tr_klass, tr_s_row = nil, nil, nil
            
            begin
                tr_db_row = TrSession.find_by({
                    language: into_language,
                    name: db_table_name    
                })
                if tr_db_row.nil?
                    db = init_translation_session(
                        into_language, db_table_name
                    )
                    return nil if db.nil?
                    data = {
                        language: into_language,
                        name: db_table_name
                    }
                    tr_db_row = TrSession.find_by!(data)
                    return nil if tr_db_row.nil?
                end 
                
                re = commit_payload_to_tr_session(
                    into_language, payload                
                ) 
                if re.nil?
                    return error_message(
                        'store_translation_session:' +
                        'commit_payload_to_tr_session(): failed.'
                    )
                end
                
                tr_db_table_as_array, tr_klass, tr_s_row = re                                
            rescue => err
                return handle_error('store_translation_session', err)
            end

            return tr_db_table_as_array, tr_klass, tr_s_row
        end
        
        # Function:
        #    - It makes a dynamic database that is a replica of  'db_table_name'. It
        #      names it by concatenating 'db_table_name' and 'into_language'.
        #    - It inits the entries of the dynamic database to nil except for the :ids
        #      which must match the :ids of the actual 'db_table_name' database. It
        #      constitutes an array of the serialized entries of the dynamic database, 
        #      so that the array is a dynamic array-version of the actual 'db_table_name'.
        #      This makes possible to persist a serialized replica of 'db_table_name'
        #      in TrSession database that exists on site.
        #    Briefly: We create a snapshot of 'db_table_name' and persist it in TrSession
        #             so we can directly modify it as a translated version of 
        #             'db_table_name'.
        #    N.B: To use the snapshot, we need to make sure the dynamic class used to 
        #         define our snapshot is still defined. To do that, it is necessary that
        #         we persist the code and attributes used in TrSession in a column
        #         called 'dynamic_code' that takes a hash = {name:, attribs:, code:}. We
        #         will use 'dynamic_code' to dynamically redefine the class before
        #         accessing the snapshot.    
        
        def init_translation_session(into_language, db_table_name)
            return nil unless valid_string?(into_language)
            return nil unless valid_string?(db_table_name)
    
            db_table_name = db_table_name
            rows_ids = nil
            attribs = nil
            klass = nil
    
            # Each column is serialized as an array of 'payload' hashes.
            # Note that 'payload' should be serialized as Hash during assignment
            # in the array.
            
            begin
                klass = Object.const_get(db_table_name)
                klass.all.each do |row|
                    rows_ids ||= Array.new
                    rows_ids << row[:id]
                end
                obj_model = klass.new
                return nil if obj_model.nil?
                attribs = get_model_net_attributes(obj_model, nil, false, true)
            rescue => err
                return handle_error('init_translation_session', err)
            end
            
            return nil if attribs.nil?
            return [] if rows_ids.nil?
            
            dyn_db_table_name = "#{db_table_name}"
            
            ret = create_dynamic_tr_db_table(
                dyn_db_table_name, attribs, into_language
            )
            if ret.nil?
                debug_write(
                    "#{self.class.to_s}::init_translation_session():"+
                    "\r\n  create_dynamic_tr_db_table(): failed to " +
                    "create #{dyn_db_table_name} db."
                )
                return nil
            end
            
            db_table, dyn_db_code = ret
            return nil if db_table.nil? || dyn_db_code.nil?
            
            dyn_db_table_name = db_table.to_s
    
            # Initializing attributes to nil
            attrs = nil
            attribs.each do |k,v|
                attrs ||= Hash.new
                attrs[k.to_sym] = nil
            end
            
            begin
                obj_db_table = db_table.new
                rows_ids.each do |id| 
                    attrs[:id] = id
                    db = obj_db_table.update_attributes(attrs)
                    if db.nil?
                        delete_dynamic_tr_db_table(dyn_db_table_name)
                        return nil
                    end
                end
            rescue => err
                handle_error('init_translation_session', err)
                delete_dynamic_tr_db_table(dyn_db_table_name)
                return nil
            end
    
            
            # Create an array that replicates the entries in db table.
            # Serialize the row as an object and push it onto the array.
            
            db = nil
            begin  
                db_table_as_array = Array.new
                db_table.all.each do |row| 
                    db_table_as_array.push(YAML::dump(row))
                end
    
                data = {
                    language: into_language,
                    name: db_table_name,
                    state: 0,
                    object: db_table_as_array,
                    dynamic_code: {
                        name: dyn_db_table_name,
                        attribs: YAML::dump(attribs),
                        code: dyn_db_code
                    }
                }
    
                db = TrSession.create!(data)
            rescue => err
                handle_error('init_translation_session', err)
                delete_dynamic_tr_db_table(dyn_db_table_name)
                return nil
            end
            
            return db_table
        end
        
        def payload_has_valid_translated?(payload)
            return false unless valid_payload_data?(payload)
            
            begin
                active_meta = payload[:active_meta]
                db_table_name = active_meta[:db_table_name]
                column = active_meta[:column_name]
                bl_translatable = active_meta[:bl_translatable]
                
                if bl_translatable
                    return false unless valid_string?(payload[:translated])
                end
            rescue
                return false
            end
            
            return true
        end
        
        def valid_payload_data?(payload)
            begin
                return false if payload.nil?
                return false unless payload.class.to_s =~ /\Ahash\z/i
                return false unless payload.key?(:to_translate)
                return false unless payload.key?(:active_meta)
                return false if payload[:active_meta].nil?
                return false unless payload[:active_meta].class.to_s =~ /\Ahash\z/i
                
                return false unless payload[:active_meta].key?(:db_table_name)
                return false unless payload[:active_meta].key?(:row_id)
                return false unless payload[:active_meta].key?(:column_name)
                return false unless payload[:active_meta].key?(:db_table_as_array_idx)
                return false unless payload[:active_meta].key?(:column_index)
                return false unless payload[:active_meta].key?(:payload_index)
                return false unless payload[:active_meta].key?(:db_array_length)
                return false unless payload[:active_meta].key?(:column_length)
                return false unless payload[:active_meta].key?(:payload_length)
                return false unless payload[:active_meta].key?(:bl_translatable)
                return false unless payload[:active_meta].key?(:mdigest)
                
                return false if payload[:active_meta][:row_id].nil?
                return false unless valid_string?(
                    payload[:active_meta][:column_name]
                )
                return false unless valid_string?(
                    payload[:active_meta][:db_table_name]
                )
                return false unless valid_string?(
                    payload[:active_meta][:row_id].to_s
                )
            rescue
                return false
            end
            
            return true
        end
        
        def equal_active_metas?(payload_1, payload_2)
            return false unless valid_payload_data?(payload_1)
            return false unless valid_payload_data?(payload_2)
            
            val = false
            val = true if payload_1[:active_meta] == payload_2[:active_meta]
            
            return val
        end
        
        def equal_to_translate_loads?(payload_1, payload_2)
            return false unless valid_payload_data?(payload_1)
            return false unless valid_payload_data?(payload_2)
            
            tr_payload = payload_1
            payload = payload_2
            
            stop_value = false
            
            in_payload = tr_payload[:payload]
            in_to_tr =  in_payload[:to_translate]
            in_meta =  in_payload[:active_meta]
            in_bl_translatable = in_meta[:bl_translatable] 
                    
            to_tr = payload[:to_translate]
            to_meta = payload[:active_meta]
            to_bl_translatable = to_meta[:bl_translatable]
                    
            if to_bl_translatable && in_bl_translatable
                reg_new = Regexp.compile(
                    '\A\s*' + Regexp.escape(in_to_tr) + '\s*\z', 'i'
                )
                stop_value = true if to_tr.match(reg_new)
            else
                stop_value = true if in_to_tr == to_tr
            end
            
            return stop_value
        end
        
        # N.B: It commits payload only if its 'to_translate' load
        #      has been previously translated. It will then merge
        #      its 'translated' part with 'payload' and return it.
        def get_payload_if_translated(into_language, payload)
            return nil unless valid_string?(into_language)
            return nil unless valid_payload_data?(payload)
            
            payload_data = nil
            
            begin
                db_table_name = payload[:active_meta][:db_table_name]
            
                ret = load_translated_payload_from_tr_session(
                    into_language, db_table_name, {}, false, true
                ) do |tr_payload, tr_klass, db_as_array, tr_s_row, row, row_data|
                    equal_to_translate_loads?(tr_payload, payload)    
                end
                
                unless ret.nil?
                    in_payload = ret[0]
                    in_tr = in_payload[:translated]
                    payload_data = payload.merge(translated: in_tr)
                end
            rescue
                return nil
            end
            
            return payload_data
        end
        
        # N.B: It commits payload only if its 'to_translate' load
        #      has been previously translated. It will then merge
        #      its 'translated' part with 'payload' and commits it.
        def dry_duplicate_to_translate_loads(into_language, payload)
            return nil unless valid_string?(into_language)
            return nil unless valid_payload_data?(payload)
            
            db_table_name = payload[:active_meta][:db_table_name]
            
            dry_payload = get_payload_if_translated(into_language, payload)
            
            unless dry_payload.nil?
                re = commit_payload_to_tr_session(
                    into_language, dry_payload                
                ) 
                if re.nil?
                    return error_message(
                        'dry_duplicate_to_translate_loads:' +
                        'commit_payload_to_tr_session(): failed.'
                    )
                end
            end
                
            return dry_payload 
        end
        
        def update_translation_session(into_language, payload)
            return nil unless valid_string?(into_language)
            return nil unless valid_payload_data?(payload)
            
            tr_session_row = nil           
            
            begin
                db_table_name = payload[:active_meta][:db_table_name]
                
                ret = load_translated_payload_from_tr_session(
                    into_language, db_table_name, {}, false, nil
                ) do |tr_payload, tr_klass, db_as_array, tr_s_row, row, row_data|
                    stop_value = equal_to_translate_loads?(tr_payload, payload) &&
                                 equal_active_metas?(tr_payload, payload)
                    if stop_value
                        i = payload[:active_meta][:db_table_as_array_idx]
                        column_name = payload[:active_meta][:column_name]
                        bl_translatable = payload[:active_meta][:bl_translatable]
                        
                        if bl_translatable
                            j = payload[:active_meta][:payload_index]
                            row_data[j] = YAML::dump(payload)
                            row[column_name.to_sym] = YAML::dump(row_data)
                        else
                            row[column_name.to_sym] = payload[:to_translate]
                        end
                        
                        db_as_array[i] = YAML::dump(row)
                        tr_s_row.object = db_as_array
                        unless tr_s_row.update_attributes(tr_s_row.attributes)
                            stop_value = false
                        end
                    end
                    
                    tr_session_row = tr_s_row  
                end
                
                if ret.nil?
                    return nil
                end
            rescue => err
                return nil
            end
                       
            return tr_session_row
        end
        
        def db_table_translation_finalized?(into_language, db_table_name)
            return false unless valid_string?(into_language)
            return false unless valid_string?(db_table_name)
            
            # raise an exception that can indicate that failure here
            # is trivial; it just means that no such table entry was
            # sessioned.
            tr_session_row = TrSession.find_by!({
                 language: into_language,
                 name: db_table_name    
            })
            return false if tr_session_row.nil?
            
            return false if tr_session_row.state == 0
            
            return true
        end
        
        def finalize_db_table_translation(into_language, db_table_name)
            return nil unless valid_string?(into_language)
            return nil unless valid_string?(db_table_name)
            
            tr_session_row = TrSession.find_by({
                 language: into_language,
                 name: db_table_name    
            })
            return {} if tr_session_row.nil?            
            
            ret = nil
            begin
                attrs = tr_session_row.attributes
            
                ret = tr_session_row.update_attributes(attrs.merge(state: 1))
                return nil if ret.nil?
            rescue => err
                return handle_error('finalize_db_table_translation', err)
            end
            
            debug_write(
                "'#{db_table_name}' translation into '#{into_language}'" +
                " finalized.", false
            )
            
            return ret
        end
        
        def persist_translation(into_language, db_table_name=nil)
            return nil unless valid_string?(into_language)
            
            model_names = nil
            db_table_names = nil
            
            if db_table_name.nil?
                db_table_names = get_db_table_names
            else
                if db_table_name.class.to_s =~ /\Aarray\z/i
                    db_table_names = db_table_name
                else
                    db_table_names ||= Array.new
                    db_table_names << db_table_name
                end
            end
            
            return nil if db_table_names.nil?
            return [] if db_table_names.empty?
            
            db_table_names.each do |tb|
                begin
                    bl = db_table_translation_finalized?(into_language, tb)
                    unless bl
                        next if ::Rails.env =~ /\Aproduction\z/i
                        return error_message(
                            "persist_translation():"+
                            "\r\ndb_table_translation_finalized?"+
                            "(#{into_language}, #{tb}): failed."
                        )
                    end
                # failure is unfair since session entry does not exist,
                # so go on with next.
                rescue 
                    next 
                end
                
                klass = load_translation_from_tr_session(into_language, tb)
                if klass.nil? 
                    next if ::Rails.env =~ /\Aproduction\z/i
                    return error_message(
                        "persist_translation():"+
                        "\r\nload_translation_from_tr_session(): failed."
                    )
                end
                
                kl_obj = inseminate_surrogate(tb, into_language)
                if kl_obj.nil? 
                    next if ::Rails.env =~ /\Aproduction\z/i
                    return error_message(
                        "persist_translation():"+
                        "\r\ninseminate_surrogate(): failed."
                    )
                end
                
                lg = SiteLanguage.set_supported_languages(into_language)
                if lg.nil?
                    next if ::Rails.env =~ /\Aproduction\z/i
                    return error_message(
                        "persist_translation():"+
                        "\r\nSiteLanguage.set_supported_languages(): failed."
                    )
                end
                
                model_names ||= Array.new
                model_names << tb
            end
            
            begin
                MetaInfo.all.each{|m| m.destroy}
                TrPayload.all.each{|m| m.destroy}
            rescue
                nothing = nil
            end
            
            return model_names
        end
        
        def get_db_table_as_array_from_tr_session(
            into_language, db_table_name
        )
            return nil unless valid_string?(into_language)
            return nil unless valid_string?(db_table_name)
            
            tr_db_table_as_array = nil
            tr_klass = nil
            begin
                tr_db_row = TrSession.find_by!({
                    language: into_language,
                    name: db_table_name
                })
                return nil if tr_db_row.nil?
                
                tr_db_table_as_array = tr_db_row.object
                dynamic_code = tr_db_row.dynamic_code
                
                # redefine dynamic class used to create snapshot
                dyn_db_table_name = db_table_name
                attribs = YAML::load(dynamic_code[:attribs])
                code = dynamic_code[:code]
                ret = create_dynamic_tr_db_table(
                    dyn_db_table_name, attribs, into_language, code
                )
                if ret.nil?
                    debug_write(
                        "#{self.class.to_s}::"+
                        "get_db_table_as_array_from_tr_session():" +
                        "\r\n  create_dynamic_tr_db_table(" +
                        #"\r\n    #{dyn_db_table_name}, " +
                        #"\r\n    #{attribs}, " + 
                        #"\r\n    #{code}" +
                        "): failed to create #{dyn_db_table_name} db."
                    )
                    return nil
                end
                tr_klass = ret[0]
            rescue => err
                return nil
            end
            
            return nil if tr_db_table_as_array.nil? || tr_klass.nil?
            
            return tr_db_table_as_array, tr_klass, tr_db_row
        end
        
        # active_meta_data: {
        #    db_table_name:
        #    row_id:
        #    column_name:
        #    db_table_as_array_idx:
        #    column_index: 
        #    payload_index:
        #    db_array_length:
        #    column_length:
        #    payload_length:
        #    bl_translatable:
        #    mdigest: 
        # }
        
        # index_metadata: meta_info_hash = {
        #                    db_table_as_array_idx:, 
        #                    column_index:, 
        #                    payload_index:
        #                 }
        #                 Initialize it to {} and then be passing the returned 
        #                 version of it until the function returns 0.
        # bl_load_class: true if you want tr session model loaded in 
        #                dynamic data model class, false otherwise.
        # stop_value: If functor is non-nil, defining this value will cause
        #             the method to return an array similar to
        #             [payload, @tr_klass, @tr_db_table_as_array] if functor 
        #             returns a value that is equal to 'stop_value', else nil
        #             is returned. Thus the continuation of the method is halted.
        # functor: block to execute. It receives translation payload loaded 
        #          from tr session as argument.
        # Return: nil on failure, [payload, index_metadata]  
        #         if (bl_load_class is false and functor nil) and 0 on completion; 
        #         [translation klass, tr db as array] if bl_load_class is true or 
        #         functor non-nil.
        def load_translated_payload_from_tr_session(
            into_language, db_table_name, 
            index_metadata={}, bl_load_class = false, 
            stop_value=nil, &functor
        )
            return nil unless valid_string?(into_language)
            return nil unless valid_string?(db_table_name)
            return nil if index_metadata.nil?
            
            tr_db_table_as_array = nil
            tr_klass = nil
            tr_db_row = nil
            tr_payload = nil
            tr_klass_obj = nil
            init_h = nil
            paragraphs = nil
            db_idx = 0
            bl_translatable = false
            
            while !db_idx.nil?
                db_idx = nil
                column_idx = nil
                py_idx = nil
                column_name = nil
                db_array_length = nil
                column_length = nil
                py_length = nil
                payload = nil
                columns = nil
            
                if index_metadata.empty?
                    index_metadata = {}
                    index_metadata[:db_table_as_array_idx] = 0
                    index_metadata[:column_index] = 0
                    index_metadata[:payload_index] = 0
                    index_metadata[:db_array_length] = 0
                    index_metadata[:column_length] = 0
                    index_metadata[:py_length] = 0
                end
                
                # debug_write("\r\nindex_metadata: #{index_metadata}\r\n") 
                
                db_idx          = index_metadata[:db_table_as_array_idx]
                column_idx      = index_metadata[:column_index]
                py_idx          = index_metadata[:payload_index]
                db_array_length = index_metadata[:db_array_length]
                column_length   = index_metadata[:column_length]
                py_length       = index_metadata[:py_length]
                
                if db_array_length <= db_idx && db_array_length > 0
                    if bl_load_class 
                        if !@tr_db_table_as_array.nil? && !@tr_klass.nil?
                            return [@tr_klass, @tr_db_table_as_array]
                        else
                            return nil
                        end
                    end
                    
                    unless functor.nil? 
                        if !@tr_db_table_as_array.nil? && !@tr_klass.nil?
                            return nil unless stop_value.nil?
                            return [@tr_klass, @tr_db_table_as_array]
                        else
                            return nil
                        end
                    end
                    return 0
                end
            
                begin
                    if @tr_db_table_as_array.nil? || @tr_klass.nil?                
                        re = get_db_table_as_array_from_tr_session(
                            into_language, db_table_name
                        )
                        if re.nil?
                            return nil
                        end
                        
                        tr_db_table_as_array, tr_klass, tr_db_row = re
               
                        @tr_db_table_as_array = tr_db_table_as_array
                        @tr_klass = tr_klass
                        @tr_session_row = tr_db_row
                        db_array_length = tr_db_table_as_array.length
                    else
                        tr_db_table_as_array = @tr_db_table_as_array
                        tr_klass = @tr_klass
                        tr_db_row = @tr_session_row
                    end
                rescue => err
                    return nil
                end
                
                if(
                    tr_db_table_as_array.nil? || tr_klass.nil? || tr_db_row.nil?
                )                   
                    return nil
                end
            
                begin
                    n_row = db_array_length
                
                    if db_idx < n_row && db_idx >= 0 
                        row = nil
                        if @row.nil?
                            @row = YAML::load(tr_db_table_as_array[db_idx])
                            return nil if @row.nil?
                            row = @row
                        else
                            row = @row
                        end
                        
                        if row.nil?
                            raise "#{self.class.to_s}::" +
                                  "load_translated_payload_from_tr_session(): " +
                                  "Exception => @row cannot be nil here."
                        end 
                    
                        row_id = row.id.to_i
                        
                        if @columns.nil?
                            @columns = get_columns(db_table_name, row_id)
                            return nil if @columns.nil?
                            columns = @columns
                            column_length = @columns.length
                        else
                            columns = @columns
                        end
                        
                        if columns.nil?
                            raise "#{self.class.to_s}::" +
                                  "load_translated_payload_from_tr_session(): " +
                                  "Exception => @columns cannot be nil here."
                        end
                    
                        # init tr klass with adequate id
                        # In case you want to load complete translation
                        # in the dynamic class so you can use it in some way.
                        if bl_load_class && init_h.nil?
                            init_h = {}
                            columns.each do |col| 
                                init_h[col.to_sym] = nil
                            end
                    
                            tr_klass_obj = tr_klass.find(row_id)
                            if tr_klass_obj.nil?
                                init_h[:id] = row_id
                                re = tr_klass.create!(init_h)
                                return nil if re.nil?
                                tr_klass_obj = tr_klass.find!(row_id)
                                return nil if tr_klass_obj.nil?
                            else
                                tr_klass_obj.update_attributes(init_h)
                            end
                        end
                    
                        if column_idx < column_length && column_idx >= 0
                            c_col = columns[column_idx]
                            column_name = c_col
                            bl_translatable = translatable?(db_table_name, c_col)
                            if bl_translatable
                                row_data = nil
                                if @row_data.nil?
                                    @row_data = YAML::load(row[c_col.to_sym])
                                    return nil if @row_data.nil?
                                    py_length = @row_data.length
                                    row_data = @row_data
                                else
                                    row_data = @row_data
                                end
                                
                                if row_data.nil?
                                    raise "#{self.class.to_s}::" +
                                          "load_translated_payload_" +
                                          "from_tr_session(): Exception =>" +
                                          " @row_data cannot be nil here."
                                end
                    
                                if py_idx < py_length && py_idx >= 0
                                    payload = YAML::load(row_data[py_idx])
                                    return nil if payload.nil?
                                    # assert that 'c_col == col in payload'
                                    active_meta = payload[:active_meta]
                                    col = active_meta[:column_name]
                                    unless col.nil? 
                                        unless c_col.match(/\A\s*#{col}\s*\z/i)
                                            raise "Exception: columns mismatch; " +
                                                  "col: #{col} should be = c_l: " +
                                                  "#{c_col}"
                                        end
                                    end
                                    py_idx += 1
                                    if py_length <= py_idx
                                        py_idx = 0
                                        column_idx += 1
                                        @row_data = nil
                                    end
                                else
                                    py_idx = 0
                                    column_idx += 1
                                    @row_data = nil
                                end
                            # non-translatable data
                            else
                                active_meta = {
                                    db_table_name: db_table_name,
                                    row_id: row_id,
                                    column_name: c_col
                                }
                                payload = {
                                    to_translate: row[c_col.to_sym],
                                    translated: row[c_col.to_sym],
                                    active_meta: active_meta
                                }
                                
                                py_idx = 0
                                column_idx += 1
                                @row_data = nil
                            end
                        else
                            column_idx = 0
                            db_idx += 1
                            @row = nil
                        end
                    end
                rescue => err
                    return nil
                end
                
                if payload.nil?
                    if db_array_length <= db_idx
                        if bl_load_class
                            if !@tr_db_table_as_array.nil? && !@tr_klass.nil?
                                return [@tr_klass, @tr_db_table_as_array]
                            else
                                return nil
                            end
                        end
                    
                        unless functor.nil? 
                            if !@tr_db_table_as_array.nil? && !@tr_klass.nil?
                                return [@tr_klass, @tr_db_table_as_array]
                            else
                                return nil
                            end
                        end
                        
                        return 0
                    end
                    return error_message(
                        'load_translated_payload_from_tr_session:' +
                        ' payload is nil.'
                    )
                end
                
                bl_loading = 
                bl_load_class && !column_name.nil? && !column_length.nil?
                
                if bl_loading
                    if init_h.nil? || !init_h.key?(column_name.to_sym)
                        raise "#{self.class.to_s}::" +
                              "load_translated_payload_from_tr_session(): " +
                              "Exception => init_h hash is invalid."
                    end
                    
                    paragraphs ||= Array.new
                    paragraphs << payload[:translated]
                    # Are we done with this column ?
                    if py_idx == 0 && column_idx > 0
                        val = join_paragraphs(
                            paragraphs, false
                        ) if paragraphs.length > 1
                        val = paragraphs[0] if paragraphs.length == 1
                        init_h[column_name.to_sym] = val
                        paragraphs = nil
                    end
                end
                
                if column_length <= column_idx
                    column_idx = 0
                    db_idx += 1
                    @row = nil
                    if bl_loading
                        if init_h.nil? || tr_klass_obj.nil?
                            raise "#{self.class.to_s}::" +
                                  "load_translated_payload_from_tr_session(): " +
                                  "Exception => init_h hash or " +
                                  "tr_klass_obj is invalid."
                        end
                        re = tr_klass_obj.update_attributes(init_h)
                        if re.nil?
                            return error_message(
                                "load_translated_payload_from_tr_session:" +
                                "update_attributes(): failed."
                            )
                        end
                        tr_klass_obj = nil
                        init_h = nil
                    end
                    
                end                             
                
                # Make sure no reloop happens before this.
                # No crucial change on the three idx values should
                # happen after this.
                index_metadata[:db_table_as_array_idx] = db_idx
                index_metadata[:column_index] = column_idx
                index_metadata[:payload_index] = py_idx
                index_metadata[:db_array_length] = db_array_length
                index_metadata[:column_length] = column_length
                index_metadata[:py_length] = py_length
                
                tr_payload = {
                    payload: payload,
                    index_metadata: index_metadata
                }
                
                unless functor.nil?                   
                    ret = functor.call(
                        tr_payload, @tr_klass,  @tr_db_table_as_array, 
                        @tr_session_row, @row, @row_data
                    ) 
                    unless stop_value.nil?
                        py = tr_payload[:payload]
                        ret_array = [py, @tr_klass, @tr_db_table_as_array]
                        return ret_array if ret == stop_value
                    end   
                end
                
                if functor.nil? && !bl_loading
                    break
                end 
                
                if db_array_length <= db_idx
                    if bl_load_class
                        if !@tr_db_table_as_array.nil? && !@tr_klass.nil?
                            return [@tr_klass, @tr_db_table_as_array]
                        else
                            return nil
                        end
                    end
                    
                    unless functor.nil? 
                        if !@tr_db_table_as_array.nil? && !@tr_klass.nil?
                            return [@tr_klass, @tr_db_table_as_array]
                        else
                            return nil
                        end
                    end
                    return 0
                end
            end
            
            return tr_payload
        end
        
        # Function: It creates a dynamic translation data base and loads
        #           'translated' data into it so that it is the translated
        #           version of 'db_table_name' into 'into_language' language.
        def load_translation_from_tr_session(into_language, db_table_name)
            return nil unless valid_string?(into_language)
            return nil unless valid_string?(db_table_name)
            
            tr_klass = nil
            
            begin
                re = load_translated_payload_from_tr_session(
                    into_language, db_table_name, {}, true
                )
                if re.nil?
                    return error_message(
                        'load_translation_from_tr_session:' +
                        'load_translated_payload_from_tr_session(): failed.'
                    )
                end
                tr_klass = re[0]
            rescue => err
                return handle_error('load_translation_from_tr_session', err)
            end
            
            return tr_klass
        end
        
        def create_dynamic_tr_db_table(
            db_table_name, attribs, into_language, code=nil
        )
            ret = define_data_model(
                db_table_name, attribs, code,"", "", "", "", 
                false, true, into_language
            )
            return nil if ret.nil?
            
            return ret
        end
        
        def delete_dynamic_tr_db_table(db_table_name)
            delete_dynamic_data_model(db_table_name)
        end
        
        def make_tr_model_name(mod_name, into_language)
            return nil unless valid_string?(mod_name)
            return nil unless valid_string?(into_language)
            
            return "#{into_language.capitalize}#{mod_name}"
        end
        
        ## END-ALGO-Compatible ##
        
        # attributes: hash whose keys are column names and whose values are type
        #             of column.
        #             N.B: if serialization is needed (for 'text' types) give the type
        #             in the format "type:serialize:type_of_object". E.g text:serialize:Hash
        # bl_ordinary: if true, then add 'language:string' and 'data:text:serialize:Object'
        #              to attributes hash. Else, do not.
        # bl_dynamic: if true, then create dynamic database table.
        #
        # Return: nil/[model_full_path, code] if bl_dynamic == false, else
        #         nil/[data model class object, code].
        # N.B: if bl_dynamic == true, then model name is made by appending
        #      language value to the initial model name. E.g 'Book', 
        #      'English' ==> BookEnglish.
        def define_data_model(
            model_name, attributes, code=nil,
            validations="", associations="", 
            callbacks="", others="", 
            bl_ordinary=true, bl_dynamic=false, lang=nil
        )
            setter(
                model_name, attributes, code,
                validations, associations, 
                callbacks, others, 
                bl_ordinary, bl_dynamic, lang
            ) 
            
            return nil unless valid_string?(@model_name)
            return nil unless valid_file?(@root)
            return nil unless valid_hash?(@attribs) 
            
            if bl_ordinary == true
                unless @attribs.key?(:language)
                    @attribs[:language] = 'string'
                end 
            
                # must be serialized as a Hash that must
                # necessarily contain :metadata key.
                unless @attribs.key?(:data)
                    @attribs[:data] = 'text:serialize:Hash'
                end 
            end 
            
            accessors = nil
            mass_assign_protection = "attr_accessor " unless valid_string?(@code)
            
            @attribs.each do |k,v|
                accessors ||= "" 
                type = v
                type = nil unless valid_string?(type)
                type ||= 'string'
                mass_assign_protection += ":#{k.to_s}, " unless valid_string?(@code)
                if type =~ /\A(.+):serialize:(.+)\z/i
                    type = $1
                    type_obj = $2
                    return nil if !(type =~ /\Atext\z/i) && !(valid_string?(@code))
                    unless valid_string?(@code)
                        @validations += "\r\n    serialize :#{k.to_s}, #{type_obj}"
                    end
                end
                
                if bl_dynamic == true
                    @dynamic_attribs ||= Hash.new
                    @dynamic_attribs[k.to_sym] = type
                end
                
                unless valid_string?(@code)
                    accessors += "\r\n    def #{k.to_s}=(value)" +
                                 "\r\n        self[:#{k.to_s}] = value" +
                                 "\r\n    end" +
                                 "\r\n    def #{k.to_s}" +
                                 "\r\n        self[:#{k.to_s}]" +
                                 "\r\n    end"
                end 
            end   
            
            unless valid_string?(@code)                         
                len = mass_assign_protection.length
                mass_assign_protection = mass_assign_protection.slice(0...len-2)
                
                ass = valid_string?(@associations) ? "\r\n    #{@associations}" : ""
                valid = valid_string?(@validations) ? "#{@validations}" : ""
                calls = valid_string?(@callbacks) ? "\r\n    #{@callbacks}" : ""
                oths = valid_string?(@others) ? "\r\n    #{@others}" : ""
            
                @code = "" +
                   "\r\n    # mass assignment protection" +
                   "\r\n    #{mass_assign_protection}" +
                   "\r\n    # Associations macro-style method invocations" +
                   ass +
                   "\r\n    # Validations" +
                   valid +
                   "\r\n    # Callbacks" +
                   calls +
                   "\r\n    # Accessors overloading" +
                   "#{accessors}" +
                   "\r\n    # Other definitions" +
                   oths
            end
            
            if bl_dynamic == true
                
                return nil if @lang.nil?
                @tb_obj = MassTranslation::Tables.new
                @model_name = make_tr_model_name(@model_name, @lang)
                return nil if @model_name.nil?
                
                klass = @tb_obj.create_data_model(@model_name, @dynamic_attribs, @code)
                return nil if klass.nil?
                
                @d_models ||= Array.new
                @d_models << @model_name
                return klass, @code
            else
            @code = "\r\nclass #{@model_name} < ActiveRecord::Base #{@code}\r\nend"
            
            file_name = parse_model_name(@model_name)
            return nil if file_name.nil?
            file_name = "#{file_name}.rb"
            
            @file = File.join(@root, 'app', 'models', file_name)
            
            File.open(@file, "wb"){|f| f.write(@code)}
            
            return @file, @code
            end
            
            return @file, @code
        end
        
        def delete_data_model(file=nil)
            unless file.nil?
                @file = file
            end
                
            return true unless valid_file?(@file)
            File.delete(@file)
        end
        
        def delete_dynamic_data_model(model_name=nil)
            unless @tb_obj.nil?
                if model_name.nil?
                    return true if @d_models.nil?
                    @d_models.each do |m|
                        @tb_obj.destroy_data_model(m)
                    end
                    @d_models = nil
                else
                    @tb_obj.destroy_data_model(model_name)
                    @d_models.delete(model_name)
                end
            end
            return true
        end
        
        def undefine_data_model(file=nil)
            unless file.nil?
                @file = file
            end
            return nil unless valid_file?(@file)
            obj = DryFileManagement::FileDryMgr.new(@file)
            code = nil
            obj.handle_file_data do |data|
                d = data.to_s
                if d =~ /\A(.*class.+\s*<\s*ActiveRecord::Base)(.+)(end\s*)\z/im
                    code = "#{$1}\r\n#{$3}"
                end
            end
            
            unless code.nil?
                File.open(@file, "wb"){|f| f.write(code)}
            end
            
            return code
        end
        
        def is_original_model?(model_name, model_lang)
            return false unless valid_string?(model_name)
            return false unless valid_string?(model_lang)
            
            deflt_lang = SiteLanguage.get_default_language
            
            return true if model_language.match(/\A#{deflt_lang}\z/i)
            
            m = model_name.match(/\A#{model_language}(.+)\z/i)
            return true if m.nil?
            
            root = m[1]
            klass = Object.const_get(root)
            return true if klass.nil?
            
            return false
        end
        
        # N.B: db table is retrieved by call its 'all' method.
        #      Then, an array made of th serialization of each table row
        #      is constituted. The array is assigned to :object column of
        #      the LaaszenSurrogateMother db table.
        # Return: nil/LaaszenSurrogateMother object created.
        def inseminate_surrogate(model_name, language)
            return nil unless valid_string?(model_name)
            return nil unless valid_string?(language)
            
            ret = nil
            begin
                klass = Object.const_get(model_name)
                if ::Rails.env =~ /\Aproduction\z/i
                    return klass if is_original_model?(model_name, language)
                end
                
                @attribs = get_model_net_attributes(klass.new, nil, false, true)
                db_table_rows = nil
                lang = nil
                klass.all.each do |row|
                    db_table_rows ||= Array.new
                    db_table_rows << YAML::dump(row)
                    lang ||= row.language
                end
                
                nme = klass.to_s
                
                ret = LaaszenSurrogateMother.find_by({language: language, name: nme})
                if ret.nil?
                    ret = LaaszenSurrogateMother.create!(
                        language: language,
                        name: nme,
                        attribs: @attribs,
                        object: db_table_rows
                    )
                end
                debug_write(
                    "LaaszenSurrogateMother: '#{nme}' in '#{language}' created.",
                    false
                )
            rescue => err
                return handle_error('inseminate_surrogate', err)
            end
            
            return ret
        end
        
        # Return: data model class object
        def get_db_table_from_surrogate(model_name, language)
            return nil unless valid_string?(language)
            return nil unless valid_string?(model_name)
            
            o_klass = Object.const_get(model_name)
            return nil if o_klass.nil?
            
            # only in production should this method not fail
            o_klass = nil unless ::Rails.env =~ /\Aproduction\z/i
            
            if(
                ::Rails.env =~ /\Aproduction\z/i &&
                is_original_model?(model_name, language)
            )
                return o_klass
            end
            
            ret = nil
            begin
                hash = {language: language, name: model_name}
                ret = LaaszenSurrogateMother.find_by!(hash)
            rescue => err
                handle_error(
                    "get_db_table_from_surrogate/'#{model_name}' in '#{language}'/", 
                    err
                )
                return o_klass
            end
            
            return o_klass if ret.nil?
            return o_klass unless ret.object?
            return o_klass unless ret.attribs?
            
            @attribs = ret.attribs
            dm = create_dynamic_tr_db_table(model_name, @attribs, language, nil)
            return o_klass if dm.nil?
            klass = dm[0]
            
            arr = nil
            ret.object.each do |row|
                begin
                    mod = YAML::load(row)
                    #debug_write("\r\n\r\n#{mod.attributes}\r\n\r\n")
                    attrs = nil
                    @attribs.each do |k,v|
                        attrs ||= Hash.new
                        attrs[k.to_sym] = mod[k.to_sym]
                    end
                    klass_obj = klass.find_by(attrs)
                    if klass_obj.nil?
                        klass_obj = klass.create!(attrs)
                    else
                        re = klass_obj.update_attributes(attrs)
                        return o_klass if re.nil?
                    end
                rescue => err
                    handle_error('get_db_table_from_surrogate', err)
                    return o_klass
                end
            end
            
            return klass
        end
        
        def get_model_class_name(file, code=nil)
            if valid_file?(file)
                name = nil
                data = nil
                f = File.open(file, "r")
                while name.nil?
                    data ||= ""
                    d = f.read(1.kilobyte).to_s
                    break if d.nil?
                    break if d.empty?
                    data += d
                    lines = data.split("\n")
                    next if lines.nil?
                    next if lines.empty?
                    lines.each do |l|
                        if l =~ /\A\s*class\s+([\w\d]+)\s*.*\z/i
                            name = $1.chomp
                            return name
                        end
                    end
                end
                return name
            elsif valid_string?(code)
                name = nil
                data = code
                lines = data.split("\n")
                return nil if lines.nil?
                lines.each do |l|
                    if l =~ /\A\s*class\s+([\w\d]+)\s*.*\z/i
                        name = $1.chomp
                        return name
                    end
                end
                return name
            else
                return nil
            end
        end
        
        # Convert from CamelCase to snake_case
        def parse_model_name(model)
            return nil unless valid_string?(model)
            return DryFileManagement::FileDryMgr.snakecase(model)
        end
        
        # Function:        Get rid of :id and :timestamps attributes
        #                  and apply types filter if demanded.
        # obj_model:       instance of a model
        # types_regex:     types to allow
        # bl_filter_types: true if type filter allowed/false otherwise
        # Return:          nil/array or hash of valid attributes of the 'obj_model'
        def get_model_net_attributes(
                obj_model, types_regex=nil, 
                bl_filter_types=false, bl_append_type=false
            )
            return nil if obj_model.nil?
            
            keys = obj_model.attribute_names
            return nil if keys.nil?
            return nil if keys.empty?
            
            attrs = nil
            keys.each do |a|
                type = attribute_type(obj_model, a)
                next if type.nil?
                if bl_filter_types && !types_regex.nil?
                    next if !(type =~ /\A#{types_regex}\z/i)
                end
                if !(a =~ /\Aid|created_at|updated_at|created_on|updated_on\z/i)
                    if bl_append_type == true
                        attrs ||= Hash.new
                        attrs[a.to_sym] = "#{type}"
                    else
                        attrs ||= Array.new
                        attrs << a
                    end
                end
            end
            
            attrs = attrs.sort if attrs.class.to_s =~ /array/i
            
            return attrs
        end
        
        # obj_model: instance of a model
        # attribute: attribute name, i.e., column name
        # Return: Rails-like data model types (e.g 'string', 'binary', 'integer', etc)
        def attribute_type(obj_model, attribute)
            return nil if obj_model.nil?
            return nil unless valid_string?(attribute)
            
            type = nil
            klass = nil
            
            begin
                klass = obj_model.class
                att = attribute.to_s
                type = klass.columns_hash[att].type.to_s
            rescue => err
                return handle_error('attribute_type', err)
            end
        end
        
        def file
            @file
        end
        
        private
        
        def setter(
            model_name, attributes, code=nil,
            validations="", associations="", 
            callbacks="", others="",
            bl_ordinary=true, bl_dynamic=false, lang=nil
        )
            @model_name = model_name
            @attribs = attributes
            @code = code
            @validations = validations
            @associations = associations
            @callbacks = callbacks
            @others = others
            @bl_ordinary = bl_ordinary
            @bl_dynamic = bl_dynamic
            @lang = lang
        end
        
        # to_reset: array of keys that match the names of metadata elements to reset.
        # to_not_reset: array of keys that match the names of metadata elements to not reset.
        def reset_metadata(to_reset=nil, to_not_reset=nil)
            metadata = get_metadata
            
            unless to_reset.nil?               
                to_reset.each do |rs|
                    metadata[rs.to_ym] = nil
                end
            end
            
            unless to_not_reset.nil?               
                to_reset = metadata.keys
                to_not_reset.each do |rs|
                    to_reset.delete(rs.to_sym)
                end
                to_reset.each do |rs|
                    metadata[rs.to_sym] = nil
                end
            end 
            
            set_metadata(metadata)
        end
        
        def get_metadata
            metadata = Hash.new
            
            metadata[:yet_model_names] = @yet_model_names
            metadata[:current_model_name] = @current_model_name
            metadata[:yet_rows] = @yet_rows
            metadata[:current_row_idx] = @current_row_idx
            metadata[:yet_columns] = @yet_columns
            metadata[:column_name] = @column_name
            metadata[:yet_phrases] = @yet_phrases
            metadata[:current_phrase] = @current_phrase
            metadata
        end
        
        def set_metadata(metadata)
            return nil if metadata.nil?
            
            unless metadata.nil?
                keys1 = get_metadata.keys
                keys2 = nil
                unless metadata.respond_to?(:keys)
                    keys2 = metadata.keys
                end
                return nil unless keys2 == keys1
            end
            
            @yet_model_names = metadata[:yet_model_names]
            @current_model_name = metadata[:current_model_name]
            @yet_rows = metadata[:yet_rows]
            @current_row_idx = metadata[:current_row_idx]
            @yet_columns = metadata[:yet_columns]
            @column_name = metadata[:column_name]
            @yet_phrases = metadata[:yet_phrases]
            @current_phrase = metadata[:current_phrase]
            metadata
        end
        
        def metadata_valid?(meta=nil)
            meta ||= @metadata
            return false if meta.nil?
            return false unless valid_hash?(meta)
            # [:o_language, :tr_language, :row_index, 
            #  :translation_index,:column_index, :phrase_index]
            if(
                !meta.key?(:o_language) ||
                !meta.key?(:tr_language) ||
                !meta.key?(:translation_index) ||
                !meta.key?(:row_index) ||
                !meta.key?(:column_index) ||
                !meta.key?(:phrase_index)
            )
                return false
            end
            return true
        end
        
        def payload_valid?(pl, bl_values=true)
            return false unless valid_hash?(pl, bl_values)
            # [:to_translate, :translated, :meta]
            if(
                !pl.key?(:to_translate) ||
                !pl.key?(:translated) ||
                !pl.key?(:meta)
            )
                return false
            end
            return false unless metadata_valid?(pl[:meta])
            return true
        end
        
        def string_valid?(str)
            DryFileManagement::FileDryMgr.valid_string?(str)
        end
        
        def valid_string?(str)
            DryFileManagement::FileDryMgr.valid_string?(str)
        end
        
        def hash_valid?(h, bl_values=true)
            DryFileManagement::FileDryMgr.valid_hash?(h, bl_values)
        end
        
        def valid_hash?(h, bl_values=true)
            DryFileManagement::FileDryMgr.valid_hash?(h, bl_values)
        end
        
        def valid_array?(a)
            DryFileManagement::FileDryMgr.valid_array?(a)
        end
        
        def array_valid?(a)
            DryFileManagement::FileDryMgr.valid_array?(a)
        end
        
        def valid_file?(f)
            DryFileManagement::FileDryMgr.valid_file?(f)
        end
        
        def file_valid?(f)
            DryFileManagement::FileDryMgr.valid_file?(f)
        end
        
        def b_to_string(bin)
            return nil if bin.nil?
            str_obj = ActiveRecord::Type::String.new
            str_obj.send(:type_cast, bin)
        end
        
        def debug_write(str, bl=true)
            log_mgr
            # return nil if ENV['RAILS_ENV'] == 'production'
            return nil unless valid_string?(str)
            if bl
                file = File.join(::Rails.root, 'log', 'log')
                data = "\r\n#{Time.now}: #{str}"
                File.open(file, "ab"){|f| f.write(data)}
                file
            end
        end
        
        def debug_delete
            # return nil if ENV['RAILS_ENV'] == 'production'
            file = File.join(::Rails.root, 'log', 'log')
            return nil unless valid_file?(file)
            File.delete(file)
        end
        
        def delete_log_file(file)
            if valid_file?(file)
                sz = File.size(file)/1.gigabyte
                File.delete(file) if sz >= 1
            end
        end
        
        def log_mgr
            file = File.join(::Rails.root, 'log', 'development.log')
            delete_log_file(file)
            file = File.join(::Rails.root, 'log', 'test.log')
            delete_log_file(file)
            file = File.join(::Rails.root, 'log', 'log')
            delete_log_file(file)
        end
    end
end
