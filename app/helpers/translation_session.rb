
#################################################################################
#    Foreign Keys(FKs) intel:                                                   #
#    1. Dynamically:                                                            #
#        "rails g migration add_level_id_to_students level_id:integer &&        #
#        rake db:migrate" will add level_id (Level model) FK to Student         #
#        model.                                                                 #
#    2. At model generation:                                                    #
#        "rails g model Student name:string level:references" will generate     #
#        Student model and add level_id FK to it.                               #
#################################################################################


module MassTranslation
    # Convention: Plural names are assumed as to 
    #             associations using macro-style methods for both partners.
    
    
    
    ##################
    #    DbTables    #
    ##################
    class Tables
        def initialize
            @tr_obj = nil
            @models = nil
        end
        
        def add_foreign_key(child_table_name, parent_table_name)
            return nil unless valid_string?(child_table_name)
            return nil unless valid_string?(parent_table_name) 
            
            fk = "#{parent_table_name.singularize}_id".to_sym
            ch = child_table_name.pluralize.to_sym
            
            begin 
                ActiveRecord::Schema.define do
                    add_column ch, fk, :integer 
                end
            rescue Exception => err
                model = DryFileManagement::FileDryMgr.camelcase(ch.to_s)
                model_name = ""
                unless model.nil?
                    model_name = model.capitalize.singularize
                    model_class = Object.const_get(model_name)
                    unless model_class.nil?
                        return true if model_class.new.respond_to?(fk)
                    end
                end
                @tr_obj = TranslationSession.new
                @tr_obj.send(:debug_write, "\r\n#{model_name}\r\n#{err.message}")
                return nil
            else
                return true
            end 
        end
        
        # pa_model_name: data model name of parent model (belongs_to argument)
        # ch_model_name: data model name of child model (has_many argument)
        # mig_path: migration folder
        # mig_regex: regular expression used to capture the right migration
        # Return: nil/[full path to migration, code in the migration file]
        def add_foreign_key_to_migration(
            pa_model_name, ch_model_name, mig_path=nil, mig_regex=nil
        )
            @tr_obj ||= TranslationSession.new
            return nil unless @tr_obj.send(:valid_string?, pa_model_name)
            return nil unless @tr_obj.send(:valid_string?, ch_model_name)
            
            ch_tb_name = @tr_obj.parse_model_name(ch_model_name)
            return nil unless @tr_obj.send(:valid_string?, ch_tb_name)
            ch_tb_name = ch_tb_name.pluralize
            
            pa_tb_name = @tr_obj.parse_model_name(pa_model_name)
            return nil unless @tr_obj.send(:valid_string?, pa_tb_name)
            pa_tb_name = pa_tb_name.pluralize
            
            path = mig_path.nil? ? 
                   File.join(::Rails.root, 'db', 'migrate') :
                   mig_path
            return nil unless @tr_obj.send(:valid_file?, path)
            
            mig_name_regex = mig_regex.nil? ? 
                             /create_#{ch_tb_name}.rb$/i : 
                             /#{mig_regex}$/i
                
            folder = path
            Dir.entries(folder).each do |e|
                if(
                    !e.match(mig_name_regex) ||
                    File.directory?(File.join(folder, e))
                )
                    next
                end
                path = File.join(folder, e)
                break
            end
                        
            return nil unless @tr_obj.send(:valid_file?, path)
            
            ch_class = Object.const_get(ch_model_name)
            return nil if ch_class.nil?
            return path, nil if ch_class.new.respond_to?(
                                    "#{pa_tb_name.singularize}_id".to_sym
                                ) 
            
            code = nil
            obj = DryFileManagement::FileDryMgr.new(path)
            obj.handle_file_data do |data|
                code = data.to_s
                m = code.match(/(create_table.+\|(.+)\|)/i)
                return nil if m.nil?
                pa = pa_tb_name
                code = "#{m.pre_match}#{m[1]}" +
                       "\r\n      #{m[2]}.belongs_to :#{pa}" +
                       "#{m.post_match}"
            end
            
            return nil if code.nil?
            
            File.open(path, "wb") { |f| f.write(code) }
            
            return path, code
        end
        
        def create_data_model(
            model_name, attributes, code=nil,
            validations="", associations="", callbacks=""
        )
            return nil unless valid_string?(model_name)
            return nil unless valid_hash?(attributes)
            
            begin
                obj = Object.const_get(model_name)
            rescue
                nothing = nil
            else
                # It is just dynamic class definition, the
                # real deal happens in  data base, so you can
                # undef the model class
                Object.send(:remove_const, model_name.to_sym)
                @models.delete(model_name) unless @models.nil?
            end
            
            code_data = code
            
            @tr_obj = TranslationSession.new
            table_name = @tr_obj.parse_model_name(model_name)
            return nil if table_name.nil?
            table_name = table_name.pluralize
            
            if code.nil?                
                accessors = nil
                attribs = nil
                mass_assign_protection = "attr_accessor "
            
                attributes.each do |k,v|
                    accessors ||= ""
                    type = v
                    type = nil unless valid_string?(type)
                    type ||= 'string'
                    mass_assign_protection += ":#{k.to_s}, "
                    accessors += "\r\n\r\n    def #{k.to_s}=(value)" +
                             "\r\n        self[:#{k.to_s}] = value" +
                             "\r\n    end" +
                             "\r\n    def #{k.to_s}" +
                             "\r\n        self[:#{k.to_s}]" +
                             "\r\n    end"
                end
            
                len = mass_assign_protection.length
                mass_assign_protection = mass_assign_protection.slice(0...len-2)
            
                code_data = "" +
                   "\r\n    # mass assignment protection" +
                   "\r\n    #{mass_assign_protection}" +
                   "\r\n    # Associations macro-style method invocations" +
                   "\r\n    #{associations}" +
                   "\r\n    # Validations" +
                   "\r\n    #{validations}" +
                   "\r\n    # Callbacks" +
                   "\r\n    #{callbacks}" +
                   "\r\n    # Accessors overloading" +
                   "\r\n    #{accessors}"
            end
                   
            Object.const_set(
                model_name,
                Class.new(ActiveRecord::Base){ code_data }
            )
            @models ||= Array.new
            @models << model_name
            
            return nil unless Tables.create_table(table_name, attributes) 
            
            Object.const_get(model_name)
        end
        
        def destroy_data_model(model_name)
            return nil unless valid_string?(model_name)
            
            begin
                Object.send(:remove_const, model_name.to_sym)
                @models.delete(model_name) unless @models.nil?
            rescue => err
                return true
            end
            
            @tr_obj = TranslationSession.new
            table_name = @tr_obj.parse_model_name(model_name)
            
            Tables.delete_table(table_name)    
        end
        
        def destroy_all_data_models
            return nil if @models.nil?
            @tr_obj = TranslationSession.new
            @models.each do |m|
                begin
                    Object.send(:remove_const, m.to_sym)
                rescue
                    next
                end
                table_name = @tr_obj.parse_model_name(m)
                Tables.delete_table(table_name)
            end 
            @models = nil
        end
        
        def Tables.create_table(tb_name, attributes)            
            return nil unless DryFileManagement::FileDryMgr.valid_string?(tb_name)
            return nil unless DryFileManagement::FileDryMgr.valid_hash?(attributes)
            
            table_name = tb_name.pluralize.to_sym
            
            begin        
                ActiveRecord::Schema.define do
                    return true if table_exists?(table_name)
                    create_table table_name do |t|
                        attributes.each do |k,v|
                            # ALT: t.column k.to_sym, v.to_sym
                            # NB: the syntax adopted allows us
                            #     to use t.belongs_to :parent, so it should
                            #     remain as is for dependency issue.
                            t.send(v.to_sym, k.to_sym)
                        end
                        t.column :created_on, :datetime
                        t.column :updated_on, :datetime
                    end
                end
                return true
            rescue => err
                @tr_obj = TranslationSession.new
                @tr_obj.send(
                    :debug_write, 
                    "#{self.class.to_s}::create_table(): #{err.message}"
                )
                return nil
            end
        end
        
        def Tables.delete_table(tb_name)
            return nil unless DryFileManagement::FileDryMgr.valid_string?(tb_name)
            
            table_name = tb_name.pluralize.to_sym
            
            begin
                ActiveRecord::Schema.define do
                    drop_table table_name
                end
                return true
             rescue Exception => err
                 #Logger.error "Error deleting table \n #{err.message}"
                 return nil
             end
        end  
        
        private
        
        def string_valid?(str)
            DryFileManagement::FileDryMgr.valid_string?(str)
        end
        
        def valid_string?(str)
            DryFileManagement::FileDryMgr.valid_string?(str)
        end
        
        def hash_valid?(h)
            DryFileManagement::FileDryMgr.valid_hash?(h)
        end
        
        def valid_hash?(h)
            DryFileManagement::FileDryMgr.valid_hash?(h)
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
    end
    
    ############################
    #    TranslationSession    #
    ############################
    
    class TranslationSession
        attr_reader :tables_obj
        # tb_obj: Tables.new object
        def initialize(tb_obj=nil)
            @proxy_model = nil
            @model_row = nil
            @attributes = nil
            @phrases = nil
            @num_phrases = 5
            @obj_translation = nil
            @translation_idx = 0 # :ids are 1-based, but init it to 0
            @row_idx = 1 # :ids are 1-based
            @column_idx = 0
            @phrase_idx = 0
            @tr_model = nil
            # @metadata = {
            #     translation_index: int # index used to get the row entry in Translation data model
            #     row_index: int # index used to get the row entry in proxy_model
            #     column_index: int # current attribute in the given row
            #     phrase_index: int # index of current phrase given an array of phrases
            # } i.e., keys == [:assoc_model_name, :row_index, :column_index, :phrase_index]
            @metadata = nil
            # cache generated models
            @generated_models = nil
            # cache generated migrations
            @generated_migrations = nil
            @tables_obj = tb_obj
            @mutex = Mutex.new
        end
        
        public
        
        def tables_obj
            @tables_obj
        end
        
        # attri: e.g {lengthened: 'French', shortened: 'Fr'}
        def create_languageshort_model(mod_name='LanguageShort', attri=nil)
            attribs = {
                lengthened: 'string',
                shortened: 'string'
            }
            validations = "\r\n    validates_presence_of :lengthened, :shortened" +
                          "\r\n    validates_length_of :shortened, :maximum => 4" +
                          "\r\n    validates_uniqueness_of :lengthened, :shortened, " + 
                          ":case_sensitive => false"
            re = create_data_model(
                mod_name, attribs, nil, validations
            )
            return nil if re.nil?
            clss = re
            
            defaults = [
                {lengthened: 'French', shortened: 'Fr'},
                {lengthened: 'English', shortened: 'En'},
                {lengthened: 'Kirundi', shortened: 'Ru'},
                {lengthened: 'Swahili', shortened: 'Sw'},
                {lengthened: 'Luganda', shortened: 'Ga'}
            ]
            
            if valid_hash?(attri)
                if(
                    valid_string?(attri[:lengthened]) && 
                    valid_string?(attri[:shortened])
                )
                    defaults.each do |d|
                        if d[:lengthened] != attri[:lengthened]
                            defaults << attri
                        end
                    end
                end
            end
                        
            defaults.each do |att|
                a = clss.new(att)
                unless a.save
                    message = ""
                    if a.errors.any?
                        a.errors.full_messages.each do |m| 
                            message += "\r\n  #{m}"
                        end
                    end
                    debug_write(
                        "#{self.class.to_s}::create_languageshort_model(): " +
                        "\r\n    param: #{att}" +
                        "\r\n    Error: could not create #{parse_model_name(mod_name)}" +
                        "\r\n    Details: #{message}"
                    )
                end
            end
                            
            return clss
        end
        
        # Expectations: It expects a model called LanguageShort that maps
        #               languages to their shortened form to exist.
        #               Its attributes are {lengthened:, shortened:}.
        #               Needless to say that 'lang' should be mapped there.
        # Return: nil/short form of 'lang' or array of short forms
        def get_shortened_language_name(lang=nil)
            
            clss = create_languageshort_model  
            return nil if clss.nil?
            suffix = nil 
                
            if lang.nil?
                all = clss.all
                return nil if all.nil?
                all.each do |l|
                    suffix ||= Array.new
                    suffix << l[:shortened]
                end
            else
                return nil unless valid_string?(lang)       
            
                langshort = clss.find_by(lengthened: lang)
                return nil if langshort.nil?
                suffix =  langshort[:shortened] 
            end
                
            return suffix
        end
        
        def squeeze_net_code_from_model(path)
            return nil unless valid_file?(path)
            
            code = nil
            fo = DryFileManagement::FileDryMgr.new(path)
            
            code =  fo.handle_file_data do |data|
                        block = data.to_s.match(/ActiveRecord::Base/i)
                        return nil if block.nil?
                        code_data = nil
                        blk = block.post_match
                        while blk = blk.match(/\s+end/i)
                            code_data ||= ""
                            code_data += blk.pre_match
                            blk = blk.post_match
                            break if blk.nil?
                        end
                        code_data.chop.chomp
                    end
            
            return code
        end
        
        # path: full path to the original model that is to be translated.
        # lang: language into which model is to be translated
        # Return: nil/[class object, net code used to create model]
        def create_translation_data_model(path, lang, code=nil)
            return nil unless valid_string?(lang)
            return nil unless valid_file?(path)
            
            suffix = get_shortened_language_name(lang)
            
            return nil if suffix.nil?
            
            # parent names
            pa_model_name = get_model_class_name(path)
            return nil unless valid_string?(pa_model_name)
            pa_assoc = parse_model_name(pa_model_name)
            return nil if pa_assoc.nil?
            pa_assoc = pa_assoc.pluralize
            
            # child names
            ch_model_name = pa_model_name + suffix.capitalize
            return nil unless valid_string?(ch_model_name)
            
            # get model attributes: ignore :id and timestamps
            attrs = nil
            obj_model = nil
            begin
                obj_model =   Object.const_get(pa_model_name)
                return nil if obj_model.nil?
                obj_model = obj_model.new
                attrs = get_model_net_attributes(obj_model)
            rescue
                return nil
            else
                nothing = nil
            end
            
            return nil if attrs.nil?
            
            # create ch model source code
            attributes = nil
            attrs.each do |a|
                type = attribute_type(obj_model, a) # attribute type
                return nil if type.nil?
                attributes ||= Hash.new 
                attributes[a.to_sym] = type
            end
            # make sure foreign key is added
            attributes[pa_assoc.singularize.to_sym] = 'belongs_to'
            
            # transfer code
            code = squeeze_net_code_from_model(path) if code.nil?
            return nil if code.nil?
            
            cl = create_data_model(ch_model_name, attributes, code)
            return nil if cl.nil?
            
            return cl, code
        end
        
        # N.B: At least one of [code, path] must be non-nil
        def add_association_macro(macro, code, path=nil)
            return nil unless valid_string?(macro)
            
            data = code
            
            if valid_file?(path)
                fo = DryFileManagement::FileDryMgr.new(path)
                data =  fo.handle_file_data{|d| d.to_s}    
            end
            
            return nil unless valid_string?(data)
            
            # conventionally
            code_data = nil
            block = data.match(/^(\s+#\s*Associations(.+))/i)
            if block.nil?
                block = data.match(/^(\s+def)/)
                return nil if block.nil?
                code_data = "#{block.pre_match}" +
                        "\r\n    # Associations macro-style method invocations" +
                        "\r\n    #{macro}" +
                        "#{$1}#{block.post_match}"
            else
                code_data = "#{block.pre_match}#{$1}" +
                        "\r\n    #{macro}" +
                        "#{block.post_match}"
            end
            
            return nil unless valid_string?(code_data)
            
            if valid_file?(path)
                File.open(path, "wb"){|f| f.write(code_data)}
            end
            
            return code_data
        end
        
        # Function: Registers a translation model to its translated parent.
        # path: full path to the original model that is to be translated.
        # lang: language into which model is to be translated
        # o_lang: original language.
        # Return: nil/[parent class object, child class object, 
        #              belong_verb argument, have_verb argument]
        def associate_translation_with_original(path, lang, o_lang=nil)
            return nil unless valid_string?(lang)
            return nil unless valid_file?(path)
            
            suffix = get_shortened_language_name(lang)
            return nil if suffix.nil?
            
            # parent names
            pa_model_name = get_model_class_name(path)
            return nil unless valid_string?(pa_model_name)
            pa_assoc = parse_model_name(pa_model_name)
            return nil if pa_assoc.nil?
            pa_assoc = pa_assoc.pluralize
            
            # child names
            ch_model_name = pa_model_name + suffix.capitalize
            return nil unless valid_string?(ch_model_name)
            ch_assoc = parse_model_name(ch_model_name)
            return nil if ch_assoc.nil?
            ch_assoc = ch_assoc.pluralize
            
            # make sure child isn't already associated with parent
            re = associates?(pa_model_name, ch_model_name)
            unless re.nil?
                return re[0], re[1], pa_assoc, ch_assoc
            end
            
            # set child association macro
            code = squeeze_net_code_from_model(path)
            macro = "belongs_to :#{pa_assoc}"
            code = add_association_macro(macro, code)
            return nil if code.nil?
            
            # create child model
            re = create_translation_data_model(path, lang, code)
            return nil if re.nil?
            ch_class = re[0]
            
            # debug
            # debug_write(re[1])
            # end
            
            # set parent association macro
            # NB: Tactical sequence; note that the above code
            #     does not modify the contents of the file at 'path',
            #     it simply uses its contents.
            macro = "has_many :#{ch_assoc}"
            re = add_association_macro(macro, nil, path)
            return nil if re.nil?
            
            # debug
            # debug_write(re)
            # end
            
            pa_class = Object.const_get(pa_model_name)
            return nil if pa_class.nil?
            
            return pa_class, ch_class, pa_assoc, ch_assoc
        end
        
        # obj_model: instance of a model
        # attribute: attribute name, i.e., column name
        # Return: Rails-like data model types (e.g 'string', 'binary', 'integer', etc)
        def attribute_type(obj_model, attribute)
            return nil if obj_model.nil?
            return nil unless valid_string?(attribute)
            obj_model.class.columns_hash[attribute].type.to_s
        end
        
        # Return: nil/[parent class object, child class object]
        def associates?(class_name1, class_name2)
            return nil unless valid_string?(class_name1)
            return nil unless valid_string?(class_name2) 
            
            class1 = nil
            class2 = nil
            begin
                class1 = Object.const_get(class_name1)
                class2 = Object.const_get(class_name2)
            rescue
                return nil
            else
                nothing = nil
            end
            
            assoc_name1 = nil
            return nil unless (assoc_name1 = parse_model_name(class_name1))
           
            assoc_name2 = nil 
            return nil unless (assoc_name2 = parse_model_name(class_name2)) 
            
            parent = nil
            child = nil
            
            begin
                if class1.new.respond_to?(assoc_name2.pluralize.to_sym)
                    parent = class1
                else
                    parent = class2 if class2.new.respond_to?(assoc_name1.pluralize.to_sym)
                end
                
                if class1.new.respond_to?("#{assoc_name2.singularize}_id".to_sym)
                    child = class1
                else
                    child = class2 if class2.new.respond_to?(
                                          "#{assoc_name1.singularize}_id".to_sym
                                      )
                end
            rescue
                return nil
            else
                nothing = nil
            end 
            
            return nil if (parent.nil? || child.nil? || child == parent)
            
            return parent, child                  
        end
        
        # child_table_name: pluralized db table name, the 'has_many'-like argument.
        # parent_table_name: pluralized db table name, the 'belongs_to'-like argument.
        def add_foreign_key(child_table_name, parent_table_name)
             @tables_obj ||= Tables.new
             @tables_obj.add_foreign_key(child_table_name, parent_table_name)
        end
        
        def add_foreign_key_to_migration(
            pa_model_name, ch_model_name, mig_path=nil, mig_regex=nil
        )
            @tables_obj ||= Tables.new
            @tables_obj.add_foreign_key_to_migration(
                pa_model_name, ch_model_name, mig_path, mig_regex
            )
        end
        
        # Function: associate models.
        # hash = { parent: #full path, child: #full path, 
        #   have: #has_many, belong: #belongs_to }
        # Return: nil/
        #         [belong_verb argument, have_verb argument, 
        #          parent class object, child class object]
        def associate(hash)
            return nil unless valid_hash?(hash)
            # validate input data
            hash.each do |k,v|
                return nil if !(k =~ /\Aparent|child|have|belong\z/i)
                if k.to_s.match('parent') || k.to_s.match('child')
                    return nil unless valid_string?(v)
                    return nil unless valid_file?(v)
                end
                if k.to_s.match('have')
                    hash[:have] = 'has_many' unless valid_string?(v)
                end
                if k.to_s.match('belong')
                    hash[:belong] = 'belongs_to' unless valid_string?(v)
                end
            end
            
            ch_class_name = get_model_class_name(hash[:child])
            pa_class_name = get_model_class_name(hash[:parent])
            
            # Already associated?
            #re = associates?(pa_class_name, ch_class_name)
            re = nil
            unless re.nil?
                pa_class = re[0]
                ch_class = re[1]
                
                pa_assoc = parse_model_name(pa_class_name)
                pa_assoc = pa_assoc.pluralize unless pa_assoc.nil?
                ch_assoc = parse_model_name(ch_class_name)
                ch_assoc = ch_assoc.pluralize unless ch_assoc.nil?
                
                if(
                    pa_assoc.nil? || ch_assoc.nil? || 
                    pa_class.nil? || ch_class.nil?
                )
                    return nil
                end
                
                return pa_assoc, ch_assoc, pa_class, ch_class
            end
            
            # parent
            ch_assoc = write_assoc_code(
                hash[:parent], hash[:have], ch_class_name
            )
            return nil if ch_assoc.nil?
            
            # child
            pa_assoc = write_assoc_code(
                hash[:child], hash[:belong], pa_class_name
            )
            return nil if pa_assoc.nil?
            
            return nil unless add_foreign_key_to_migration(
                                  pa_class_name.to_s, ch_class_name.to_s
                              )
            
            #return nil unless add_foreign_key(ch_assoc, pa_assoc)
            
            pa_class = Object.const_get(pa_class_name)
            ch_class = Object.const_get(ch_class_name)
            return pa_assoc, ch_assoc, pa_class, ch_class
        end
        
        # used by 'associate' method
        # assoc_name: Model Class name. 
        #             I will first snake_case it and then pluralize it.
        # Return: association model name used with 'assoc_verb'
        def write_assoc_code(file, assoc_verb, assoc_name)
            return nil if file.nil? || assoc_verb.nil? || assoc_name.nil?
            return nil if file.empty? || assoc_verb.empty? || assoc_name.empty?
            if (
                file =~ /\A\s+\z/ || assoc_verb =~ /\A\s+\z/ || 
                assoc_name =~ /\A\s+\z/
            )
                return nil
            end
            pa_lines = nil
            # read
            File.open(file, "r") do |f|
                pa_code = f.read.to_s
                if !pa_code.nil?
                    if !pa_code.empty? && !(pa_code =~ /\A\s+\z/)
                        pa_lines ||= Array.new
                        pa_lines = pa_code.split("\n")
                    end
                    pa_lines, assoc_name = insert_assoc_line(
                                               pa_lines, assoc_verb, assoc_name
                                           )
                end
            end
            # write
            return nil if pa_lines.nil?
            return nil if pa_lines.empty?
            File.open(file, "w") do |f|
                pa_lines.each do |line|
                    f.write(line.chomp + "\r\n")
                end
            end
            return assoc_name
        end
        
        # used by 'associate' method
        # assoc_name: Model Class name. 
        #             I will first snake_case it and then pluralize it.
        # Return: [
        #            array of code lines, 
        #            association model name used with 'assoc_verb'
        #         ]
        def insert_assoc_line(pa_lines, assoc_verb, assoc_name)
            return nil if assoc_verb.nil? || assoc_name.nil? || pa_lines.nil?
            return nil if assoc_verb.empty? || assoc_name.empty? || pa_lines.empty?
            return nil if assoc_verb =~ /\A\s+\z/ || assoc_name =~ /\A\s+\z/
            if !pa_lines.nil?
                len = pa_lines.length
                pa_assoc_name = parse_model_name(assoc_name)
                0.upto len-1 do |i|
                    # if ever u're 'convention over configuration'
                    if pa_lines[i] =~ /^(\s*)#\s*Associations/i
                        next if pa_assoc_name.nil?
                        next if pa_assoc_name.empty?
                        next if pa_assoc_name =~ /\A\s+\z/
                        assoc_name = pa_assoc_name.pluralize
                        line = "    #{assoc_verb} :#{assoc_name}"
                        pa_lines.insert(i+1, line)
                        break   
                    end
                    # if ever u're not 'convention over configuration'
                    if pa_lines[i] =~ /^(\s*)def\s+/
                        next if pa_assoc_name.nil?
                        next if pa_assoc_name.empty?
                        next if pa_assoc_name =~ /\A\s+\z/
                        assoc_name = pa_assoc_name.pluralize
                        line1 = "    # Associations macro-style method invocations"
                        line2 = "    #{assoc_verb} :#{assoc_name}"
                        pa_lines.insert(i-2, line1)
                        pa_lines.insert(i-1, line2)
                        break   
                    end
                end
            end
            return pa_lines, assoc_name
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
        # Return:          nil/array of valid attributesof the 'obj_model'
        def get_model_net_attributes(obj_model, types_regex=nil, bl_filter_types=false)
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
                if !(a =~ /\Aid|created_at|updated_at\z/i)
                    attrs ||= Array.new
                    attrs << a
                end
            end
            attrs
        end
        
        # Function: create translation child model if it does not exist
        #           and get its instance object thru its parents.
        # obj_translation: instance of persistent entry of Translation
        #                  the kind returned by Translation.find(:id) method.
        # o_model: instance of model being translated.
        # into: language into which to translate
        # Return: proxy_object object of the translated child model.
        def get_translated_child_model(obj_translation, o_model, into)
            return nil if obj_translation.nil? || o_model.nil?
            
            # get path to model being translated
            pa_path = passenger_path(obj_translation)
            
            # register model if it is not
            re = associate_translation_with_original(pa_path, into, o_model)
            
            # get child object of original language model
            return nil if re.nil?
            return nil if re.class.to_s != 'Array' || re.empty?
            
            assoc_name = nil
            if re.length == 2
                # infer from rails command line returned
                return nil if !(match = re[0].match(/model\s+(.+)\s+/i))
                assoc_name = parse_model_name($1)
                return nil unless valid_string?(assoc_name)
                assoc_name = assoc_name.pluralize
            elsif re.length == 3
                assoc_name = re[0]
            else
                return nil
            end
            
            return nil unless valid_string?(assoc_name)
            
            # are they associated for real?, i.e., can u call child from parent?
            return nil if !o_model.respond_to?(assoc_name.to_sym)
            
            # get child object thru parent model
            proxy_model = o_model.send(assoc_name.to_sym)
            @tr_model = proxy_model if proxy_model.nil?
            
            return proxy_model
        end
        
        # obj_translation: instance of persistent entry of Translation
        #                  the kind returned by Translation.find(:id) method.
        # Return: path to registered model.
        def passenger_path(obj_translation)
            return nil if obj_translation.nil?
            tr = obj_translation
            ch_mod = tr.child_model
            pa_mod_name = ch_mod.split('#') if !ch_mod.nil?
            pa_mod_path = pa_mod_name[0] if !pa_mod_name.nil?
            return nil unless valid_file?(pa_mod_path)
            pa_mod_path
        end
        
        # obj_model: model instance
        # Return: [obj instance, column attribute]
        def get_translated_child_column(obj_model, row_idx, col_idx)
            return nil if obj_model.nil?
            
            obj_class = obj_model.class
            obj = obj_class.find(row_idx)
            return nil if obj.nil?
            
            attrs = get_model_net_attributes(obj, 'string|text|binary', true)
            return nil if attrs.nil?
            col = nil
            col ||= attrs[col_idx] if attrs.length > col_idx && col_idx > 0
            return [obj, col]
        end
        
        # obj: instance of child model
        # foreign_key: id referring to its father model.
        #              Its format is: downcased_singularized_father_name + "_id"
        #              E.g translation_id (if child of Translation model)
        def has_foreign_key?(obj, foreign_key)
            return false if obj.nil?
            return false unless valid_string?(foreign_key)
            obj.respond_to?(foreign_key.to_sym)
        end
        
        def destroy_all_data_models
            @tables_obj ||= Tables.new
            @tables_obj.destroy_all_data_models
        end
        
        def destroy_data_model(model_name)
            @tables_obj ||= Tables.new
            @tables_obj.destroy_data_model(model_name)    
        end
        
        # attributes: a hash whose keys are model columns and 
        #             whose values are column types
        # Return: nil/class object of the created model
        def create_data_model(
            model_name, attributes, code=nil,
            validations="", associations="", callbacks=""
        )
            @tables_obj ||= Tables.new
            @tables_obj.create_data_model(
                model_name, attributes, code, 
                validations, associations, callbacks
            )
        end
        
        # attributes = {
        #     meta: @metadata (string), # serialize as a hash
        #     o_data: original text(string), 
        #     tr_data: translated text(string)
        # }
        # Return: nil/translation session class object.
        def create_translation_session_model(model_name)
            return nil unless valid_string?(model_name)
            attributes = {
                meta: 'text',
                o_data: 'text',
                tr_data: 'text'
            }
            validations = "\r\n    validates_presence_of :meta, :o_data, :tr_data" +
                          "\r\n    validates_length_of :meta, :o_data, :tr_data, " +
                          ":maximum => 5.kilobytes" +
                          "\r\n    validates_uniqueness_of :o_data, :tr_data, " +
                          ":case_sensitive => false" +
                          "\r\n    serialize :meta, Hash"
            return create_data_model(
                model_name, attributes, nil, validations
            )
        end
        
        # lang_suffix: short form of language. E.g 'En' for 'English'
        # Return: (array of if 'lang_suffix' = nil) translation session class object(s)
        def get_translation_session_class(lang_suffix=nil)
            if lang_suffix.nil?
                suffixes = get_shortened_language_name
                return nil unless valid_array?(suffixes)
                classes = nil
                suffixes.each do |suf|
                    session_class = get_translation_session_class(suf)
                    next if session_class.nil?
                    classes ||= Array.new
                    classes << session_class
                end
                return classes
            else
                cl_tr_session = "TranslationSession#{lang_suffix}"
                return create_translation_session_model(cl_tr_session)
            end
        end
        
        # tr_language: if nil, then delete all translation sessions
        def delete_translation_session(tr_language=nil)
            
            classes = nil
            suffix = get_shortened_language_name(tr_language)
            session_model_name = get_translation_session_class(suffix)
            
            if valid_array?(session_model_name)
                classes = session_model_name
            else
                if valid_string?(session_model_name)
                    classes ||= Array.new
                    classes << session_model_name
                end
            end
            
            if classes.nil?
                return nil
            else
                classes.each do |cl|
                    destroy_data_model(cl.to_s)
                end
            end
            
            return true    
        end
        
        # it uses TranslationSession model and @metadata intel to store
        # the data until whole model(row in Translation model) is translated.
        # payload = {to_translate: '', translated: '', meta: @metadata}
        # @metadata = {
        #     o_language: string # original language
        #     tr_language: string # translation language
        #     translation_index: int # index used to get the row entry in Translation data model
        #     row_index: int # index used to get the row entry in proxy_model
        #     column_index: int # current attribute in the given row
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
        # Return: nil/[TranslationSession class, stored hash]
        def store_translation_session(payload, tr_lang=nil)
            return manage_translation_session(payload, true, tr_lang)
        end
        
        # Return: nil/session class or array of session classes if 'tr_language' is nil
        def load_translation_session(tr_language=nil)
            ret = nil
            if tr_language.nil?
                ret = get_translation_session_class
            else
                re = manage_translation_session(nil, false, tr_language)
                return nil if re.nil?
                ret = re[0]
            end
            
            return ret
        end
        
        def manage_translation_session(payload, bl_store=true, tr_lang=nil)
            tr_data = nil
            
            if bl_store == true
                unless payload_valid?(payload)
                    debug_write("Invalid translation session data: payload")
                    return nil
                end
            
                tr_language = tr_lang.nil? ? payload[:meta][:tr_language] : tr_lang
                
                tr_data = {
                    meta: payload[:meta],
                    o_data: payload[:to_translate],
                    tr_data: payload[:translated]
                }
            else
                return nil unless valid_string?(tr_lang)
                tr_language = tr_lang
            end
            
            suffix = get_shortened_language_name(tr_language)
            if suffix.nil?
                debug_write(
                    "#{self.class.to_s}::get_shortened_language_name"+
                    "(#{tr_language}): failed."
                )
                return nil
            end
            
            session_class = get_translation_session_class(suffix)
            if session_class.nil?
                debug_write(
                    "#{self.class.to_s}::get_translation_session_class"+
                    "(#{suffix}): failed."
                )
                return nil
            end
            
            tr_sess = nil
            begin
                if bl_store == true
                    if tr_data.nil?
                        debug_write("Invalid translation data: tr_data.")
                        return nil
                    end
                    tr_sess = session_class.create!(tr_data)
                    debug_write("Translation Session stored: #{tr_data}", false) 
                else
                    tr_sess = session_class 
                    debug_write("Translation Session Retrieved.", false)
                end
                return session_class, tr_data
            rescue Exception => err
                debug_write(
                    "#{self.class.to_s}::manage_translation_session: "+
                    "\r\n    #{err.message} #=> data: #{tr_data}"
                )
                return nil
            end
            
            return session_class, tr_data
        end
        
        # Function: Registers a model with Translation
        # return: [valid :id, child_name] on success,
        #         nil on failure
        def register_for_translation(model_path, model_language=nil, bl_create=true)
            return nil unless valid_file?(model_path)
            tr_path = File.join(::Rails.root, 'app', 'models', 'translation.rb')
            return nil unless valid_file?(tr_path)
            
            #debug_write("Registering: #{model_path}")
            
            model_lang = model_language
            
            model_name = get_model_class_name(model_path)
            return nil if model_name.nil?
            assoc_name = parse_model_name(model_name)
            return nil if assoc_name.nil?
            assoc_name = assoc_name.pluralize
            
            attributes = {
                target_languages: valid_string?(model_lang) ? model_lang : 'English',
                translation_state: '',
                child_model: "#{model_path}#" + "#{assoc_name}",
                translation_unit: ''
            }
            
            tr = nil
            
            begin
                if bl_create == true
                    tr = Translation.find_by({
                        child_model: attributes[:child_model]}
                    )
                    tr = Translation.create!(attributes) if tr.nil?
                else
                    id = -1
                    tr = Translation.find_by!({
                        child_model: attributes[:child_model]}
                    )
                    unless tr.nil?
                        id = tr.id
                        tr.destroy!
                    end
                    return id, assoc_name
                end
            rescue Exception => err
                debug_write("#{err.message}")
                return nil
            else
                return tr.id, assoc_name
            end
            
            return nil if tr.nil?
            
            return tr.id, assoc_name
        end
        
        # bl_create: false(unregister) or true(register)
        # model_full_paths: array of full paths to models
        def register_data_models_for_translation(bl_create=true, model_full_paths=nil)
            model_paths = model_full_paths
        
            if model_paths.nil?
                folder = File.join(::Rails.root, 'app', 'models')
                Dir.entries(folder).each do |e|
                    if(
                        e =~ /\A\.|\.\.|translation.rb\z/i || 
                        e =~ /~|\.up\.rb$/i || # backup files
                        File.directory?(File.join(folder, e))
                    )
                        next
                    end
                    model_paths ||= Array.new
                    model_paths << File.join(folder, e)
                end
            end
        
            return nil if model_paths.nil?
            
            ret = nil
            model_paths.each do |mp|
                re = register_for_translation(mp, bl_create)
                if re.nil?
                    debug_write(
                        "#{self.class.to_s}::register_data_models_for_translation():" +
                        "\r\n    register_for_translation(#{mp})"
                    )
                    return nil
                end
                h = {
                    id: re[0],
                    child_name: re[1],
                    path: mp
                }
                ret ||= Array.new
                ret << h
            end
            return ret
        end
        
        # payload = {to_translate: '', translated: '', meta: @metadata}
        # @metadata = {
        #     o_langauge: string # original language
        #     tr_language: string # translation language
        #     translation_index: int # index used to get the row entry in Translation data model
        #     row_index: int # index used to get the row entry in proxy_model
        #     column_index: int # current attribute in the given row
        #     phrase_index: int # index of current phrase given an array of phrases
        # }
        # Return: payload-like hash half-full on success, nil on failure,
        #         empty hash on row completion, 0 on db table completion.
        def translate(from, into, payload = {}, obj_tr=nil)
            return nil unless valid_string?(from)
            return nil unless valid_string?(into)
            
            payload ||= {}
            @obj_translation ||= obj_tr
            
            @current_metadata ||= Hash.new
            @current_metadata[:translation_index] = @translation_idx
            @current_metadata[:row_index] = @row_idx
            @current_metadata[:column_index] = @column_idx
            @current_metadata[:phrase_index] = @phrase_idx
            @current_metadata[:payload] = payload
            
            debug_write(
                "Attempting to load and store translation session ...", false
            )
            
            # Should you commit translation
            if payload_valid?(payload)
                re = store_translation_session(payload, into)
                return nil if re.nil?
                @metadata = payload[:meta]
            elsif payload != {} && payload.key?(:meta)
                @metadata = payload[:meta]
            else
                # try and load metadata from translation session db table
                re = load_translation_session(into)
                return nil if re.nil?
            
                unless re.nil?
                    count = re.count
                    unless count == 0
                        begin
                            obj = re.find(count)
                            debug_write("Retrieving Session ...", false)
                            @metadata = deserialize(obj[:meta]) # deserialize to Hash
                        rescue Exception => err
                            debug_write(
                                "#{self.class.to_s}::translate:"+
                                "\r\nload_translation_session():#{err.message}"
                            )
                            return nil
                        end
                    end
                end
            end
            
            unless @metadata.nil?
                debug_write("metadata: #{@metadata}", false)
                @translation_idx = @metadata[:translation_index]
                @row_idx = @metadata[:row_index]
                @column_idx = @metadata[:column_index]
                @phrase_idx = @metadata[:phrase_index]
            end
            
            @translation_idx = @translation_idx < 1 ? 1 : @translation_idx
            
            debug_write(
                "Managing translation object. Is i nil? : "+
                "#{@obj_translation.nil?.to_s} ...", false
            )
            
            # whole db table traversed ?
            begin
                if Translation.count < @translation_idx
                    @obj_translation = nil
                    @proxy_model = nil
                    @row_idx = 1
                    @column_idx = 0
                    @phrase_idx = 0
                    set_metadata(from, into, 'Translation Complete.')
                    return 0
                end
            
                # manage translation object
                if @obj_translation.nil?       
                    @obj_translation = Translation.find(@translation_idx)
                end
            rescue => err
                debug_write("#{self.class.to_s}.translate():#{err.message}")
                return nil
            end
            
            return nil if @obj_translation.nil?
            
            debug_write("__START__", false)
            debug_write(
                "Getting @proxy_model. Is i nil? : "+
                "#{@proxy_model.nil?.to_s}...", false
            )
            
            o_model_name = nil
            if @proxy_model.nil?
                o_model_name = @obj_translation[:child_model]
                return nil unless valid_string?(o_model_name)
            
                o_model_name = o_model_name.split('#') # path#assoc_name
                return nil if o_model_name.length < 2
                o_model_name = o_model_name[1]
            
                return nil if !@obj_translation.respond_to?(o_model_name.to_sym)
                @proxy_model = Object.const_get(o_model_name.singularize.capitalize)
                return nil if @proxy_model.nil?
            
                return nil unless @proxy_model.respond_to?(:count)
            end
            
            debug_write(
                "Testing '#{o_model_name}' completion " +
                "#{@row_idx}=?#{@proxy_model.count}...", false
            )
            
            # table (model) completion ?
            if @row_idx > @proxy_model.count 
                model_name = nil
                id = @proxy_model.count
                if id > 0
                    mod = @proxy_model.find(id)
                    model_name = mod.class.to_s unless mod.nil?
                else
                    model_name = @proxy_model.class.to_s
                end
                
                @obj_translation = nil
                @translation_idx += 1
                @proxy_model = nil
                @row_idx = 1
                @column_idx = 0
                @phrase_idx = 0
                set_metadata(from, into, 'Entry Translation Complete.')
                debug_write("Translation of #{model_name} Complete.")
                @metadata = nil
                return {}
            end
            
            debug_write("Handling column data ...", false)
            
            if @column_idx == 0
            
                @model_row = nil
                mod = nil
                begin
                    mod = @proxy_model.find(@row_idx)
                rescue Exception => err
                    debug_write(
                        "#{self.class.to_s}.translate():#{err.message}"
                    )
                    return nil
                else
                    @model_row = mod
                end
            
                return nil if @model_row.nil?
            
                @attributes = get_model_net_attributes(
                    @model_row, 'string|text|binary', true
                )
                return nil if @attributes.nil?                
            end
            
            # row completion ?
            if @column_idx >= @attributes.length 
                @row_idx += 1
                @column_idx = 0
                @phrase_idx = 0
                meta, h = set_metadata(from, into, 'Entry Row Translation Complete.')
                unless h.nil?
                    h.merge(translated: '')
                end
                return translate(from, into, h)
            end
            
            debug_write("Handling phrases ...", false)
            
            if @phrase_idx == 0
                column = @attributes[@column_idx]
                unless @model_row.respond_to?(column.to_sym)
                    debug_write(
                        "#{self.class.to_s}::translate: " +
                        "\r\n    #{@model_row.to_s} should respond to " +
                        "#{column.to_sym}"
                    )
                    return nil
                end
                
                # what type of data?
                type = attribute_type(@model_row, column)
                unless valid_string?(type)
                    debug_write(
                        "#{self.class.to_s}::translate:" +
                        "\r\nattribute_type(#{@model_row.to_s},#{column}):" +
                        " 'type' is invalid string."
                    )
                    return nil
                end
            
                # This value might be big data for 'text' and 'binary' content,
                # So think of handling it best!!
                value = @model_row.send(column.to_sym)
                
                if value.nil?
                    debug_write(
                        "#{self.class.to_s}::translate: 'value' is nil."
                    )
                    return nil
                end
                
                value = value.to_s
                unless valid_string?(value)
                    debug_write(
                        "#{self.class.to_s}::translate: 'value' " +
                        "is invalid string."
                    )
                    return nil
                end
                
                @phrases = value.split(".")
            end
            
            if @phrases.nil?
                debug_write(
                    "#{self.class.to_s}::translate: '@phrases' is nil."
                )
                return nil
            end
            
            # How many phrases at a time?
            num = @phrases.length < @num_phrases ? @phrases.length : @num_phrases
            
            # column completion ?
            if @phrase_idx >= @phrases.length 
                @column_idx += 1
                @phrase_idx = 0
                meta, h = set_metadata(from, into, 'Entry Row Column Translation Complete.')
                unless h.nil?
                    h.merge(translated: '')
                end
                return translate(from, into, h)
            end
            
            debug_write("Packaging :to_translate data ...", false)
            
            data = nil
            start_idx = @phrase_idx
            end_idx = @phrase_idx + num
            phz = @phrases[start_idx...end_idx]
            phz.each do |e| 
                data ||= "" 
                data += e
            end 
            
            unless valid_string?(data)
                @phrase_idx += num
                @metadata, h = set_metadata(from, into, 'Invalid :to_translate data.')
                unless h.nil?
                    h.merge!(translated: '')
                end
                return translate(from, into, h)
            end
            
            @phrase_idx += num
            
            @metadata, h = set_metadata(from, into)
            
            h = {
                to_translate: data,
                translated: '',
                meta: @metadata               
            }    
            
            debug_write("__END__", false)
            
            return h
        end
        
        def set_metadata(from, into, data=nil)
            @metadata ||= Hash.new
            @metadata[:o_language] = from
            @metadata[:tr_language] = into
            @metadata[:translation_index] = @translation_idx
            @metadata[:row_index] = @row_idx
            @metadata[:column_index] = @column_idx
            @metadata[:phrase_index] = @phrase_idx
            h = nil
            unless data.nil?
                h = {
                    to_translate: data,
                    translated: "::#{data.upcase}::",
                    meta: @metadata               
                } 
                # Should you commit translation
                if payload_valid?(h)
                    debug_write("Resetting Stored Session ...", false)
                    re = store_translation_session(h, into)
                    return nil if re.nil?
                end
            end
            return @metadata, h
        end
        
        def deserialize(str)
            return nil unless valid_string?(str)
            m = str.match /\{(.+)\}/i
            return nil if m.nil?
            n_str = m[1]
            e = n_str.split(",")
            h = nil
            e.each do |ee|
                a = ee.split("=>")
                return nil unless a.length == 2
                
                m = a[0].match /:(.+)/i
                return nil if m.nil?
                key = m[1]
                
                m = a[1].match /\W+(.+)\W+/i
                m = a[1].match /\W*(.+)\W*/i if m.nil?
                return nil if m.nil?
                value = m[1]
                
                h ||= Hash.new
                h[key.to_sym] = value.match(/\A\d+\z/) ? value.to_i : value
            end
            
            return h
        end
        
        def set_current_metadata(meta)
            @current_metadata = meta
        end
        
        def get_current_metadata
            @current_metadata
        end
        
        private
        
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
end
