require 'rails_helper'
include Rails.application.routes.url_helpers

RSpec.describe ApplicationHelper, :type => :helper do
  
    before(:each) do
        @philo = File.join(
                     ENV['HOME'], 'a--mounts', 'STUFFS', 'COURS', 
                     'Research', 'Philosophy', 'ManImmortalityOrInexistence'
                 )
        @file =  File.join(@philo, 'Man.txt')
        @file_s =  File.join(@philo, 'UniversalSupremeCourtOfJustice')
                
        @attr = {
            language: 'English',
            theme: 'Man - Prospects of Immortality or Non-existence',
            author: 'Obed Edom Nkezabahizi',
            content: helper.read_binaries(@file)
        }
        @attr_s = {
            language: 'English', 
            author: 'Obed Edom Nkezabahizi', 
            theme: 'Man - Prospects of Immortality or Non-existence', 
            topic: 'Univesal Supreme Court Of Justice', 
            content: helper.read_binaries(@file_s)
        }
        
        @book = Book.new(@attr)
        @slide = Slide.new(@attr_s)
     end
  
    describe "ApplicationHelper" do
        it "#collapsibles returns array of hashes with :content filled" do
            hashes = helper.book_collapse(@book)
      
            expect(hashes).to_not be_nil
      
            hashes.each do |hash|     
                !hash['header'].nil?
                !hash['content'].nil?
            end
        end
    end
    
    describe "FileDryMgr" do
        before(:each) do
            @file = File.join(::Rails.root, 'app', 'models', 'book.rb')
            @file1 = File.join(::Rails.root, 'public', 'uploads', 'lang.rb')
            @hash = {
                pattern: "book",
                replacement: "Novel",
                all?: false
            }
            @backup = helper.backup(@file)
        end
        
        after(:each) do
            helper.recover(@file, @backup)
            File.delete(@file1) if File.exists?(@file1)
        end
        
        describe "::handle_file_data (args validity)" do
            it "should return nil on invalid data input" do
                fo = helper.handle_file_data(nil)
                ret = fo.handle_file_data
                expect(ret).to be_nil
                fo = helper.handle_file_data(@file)
                ret = fo.handle_file_data
                expect(ret).to be_nil
            end
        end
        
        describe "::handle_file_data (replace functionality)" do
            it "should replace patterns if hash input valid" do
                fo = helper.handle_file_data(@file, @hash)
                ret = fo.handle_file_data
                expect(ret).to_not be_nil
                expect(ret).to respond_to :data
                expect(ret.data.to_s).to match /#{@hash[:replacement]}/
            end
        end
        
        describe "::handle_file_data (block management)" do
            it "should handle a block correctly" do
                fo = helper.handle_file_data(@file)
                data = fo.handle_file_data do |d|
                    File.open(@file1, "wb") { |f| f.write(d) }
                    d 
                end
                expect(data).to_not be_nil
                expect(data.to_s).to match /class\s*book/i
                f = File.open(@file1, "rb")
                expect(f.read.to_s).to eql(data)
            end
        end
        
        describe ", as to files coordination, " do
            it "should compare two files effectively" do
                fo = helper.handle_file_data(@file)
                cmp = fo.compare_to(@file)
                expect(cmp.to_s).to eql("true")
                cmp = fo.compare_to(@file1)
                expect(cmp.to_s).to eql("false")
            end
            
            it "should copy data to another file successfully" do
                fo = helper.handle_file_data(@file)
                ret = fo.copy_to(@file1)
                expect(ret).to_not be_nil
                f = File.open(@file1, "r")
                expect(f).to_not be_nil
                bl = File.exists?(@file1)
                expect(bl.to_s).to eql("true")
                bl = File.zero?(@file1)
                expect(bl.to_s).to eql("false")
                cmp = fo.compare_to(@file1)
                expect(cmp.to_s).to eql("true")
            end
        end
    end
    
    describe "BackupFile" do
        before(:each) do
            @book_file = File.join(::Rails.root, 'app', 'models', 'book.rb')
            @data = ""
            File.open(@book_file, "rb") do |f|
                @data = f.read.to_s
            end
        end
        
        it "should backup a file and retrieve it entirely" do
            obj = helper.backup(@book_file)
            expect(obj).to_not be_nil
            o = helper.recover(@book_file, obj)
            expect(o).to_not be_nil
            expect(o.data).to eql(@data)
            File.exists?(o.bfilename)
        end
    end
    
    describe "LaaszenModel::DataModel" do
        before(:each) do
            @data_model = LaaszenModel::DataModel.new(::Rails.root)
        end
        
        after(:each) do 
            helper.delete_dynamic_data_model(nil, @data_model) 
        end
        
        it "should define data model code" do
            re = helper.define_data_model(
                'Samp', {amazi:'string', ararya:'string'},
                nil, "", "", "", "", true, false, nil, @data_model
            )
            expect(re).to_not be_nil
            re = helper.undefine_data_model(nil, @data_model)
            expect(re).to_not be_nil
            re = helper.delete_data_model(nil, @data_model)
            expect(re).to_not be_nil
            expect(File.exists?(@data_model.file).to_s).to eql("false")
        end
        
        it "should impregnate LaaszenSurrogateMother database" do
            attrib = {
                language: 'English',
                theme: 'Man - Prospects of Immortality or Non-existence',
                author: 'Obed Edom Nkezabahizi',
                content: 'So that is what it is all about, right?'
            }
            re = Book.create!(attrib)
            expect(re).to_not be_nil
            re = helper.inseminate_surrogate('Book', 'English', @data_model)
            expect(re).to_not be_nil
            
            re = helper.get_db_table_from_surrogate('Book', 'English', @data_model)
            expect(re).to_not be_nil
            expect(re).to eql(Object.const_get('EnglishBook'))
            re = re.find_by(attrib)
            expect(re).to_not be_nil
            
            attrib_new = {
                language: re[:language],
                theme: re[:theme],
                author: re[:author],
                content: re[:content]
            }
            
            expect(attrib_new).to eql(attrib)
        end
        
        it "should traverse all translatable data models" do
            re = @book.save!
            expect(re.to_s).to eql("true")
            payload = nil
            data = nil
        end
        
        it "should know translatable data models" do
            re = helper.get_db_table_names(nil, @data_model)
            expect(re).to_not be_nil
        end
        
        it "should get the ids, columns and data in a data model" do
            re = @book.save!
            expect(re.to_s).to eql("true")
            
            re = helper.get_rows_ids('Book', @data_model) 
            expect(re).to_not be_nil
            id = re.pop
            expect(id.to_s).to match /\A\d+\z/
            
            re = helper.get_columns('Book', id, @data_model)
            expect(re).to_not be_nil
            columns = re
            expect(columns).to_not be_nil
            
            re = []
            while re == []
                column = columns.pop
                break if columns.empty?
                re = helper.get_phrases('Book', id, column, @data_model)
                expect(re).to_not be_nil
                next if re == []
                phrase = re.pop
                expect(phrase).to_not be_nil
            end
        end
        
        it "should manage graph successfully" do
            re = @book.save!
            expect(re.to_s).to eql("true")
            
            re = @slide.save!
            expect(re.to_s).to eql("true")
            
            re = helper.load_metadata('Kirundi', @data_model)
            expect(re).to_not be_nil
            metadata = re
            data = nil
            while data != 0
                re = helper.manage_graph_state('Kirundi', metadata, @data_model) 
                expect(re).to_not be_nil
                if re.class.to_s =~ /array/i
                    payload, metadata = re
                    #helper.debug_write("\r\n#{payload[:to_translate]}")
                else
                    break if re == 0
                end
            end
        end
        
        it "should load/store_metadata successfully using :translate" do
            re = @book.save!
            expect(re.to_s).to eql("true")
            
            re = @slide.save!
            expect(re.to_s).to eql("true")
            
            payload = {}
            data = nil
            
            while data != 0
                data = helper.laaszen_translate(
                    'English', 'Kirundi', payload, @data_model
                ) 
                expect(data).to_not be_nil
                if data.class.to_s =~ /hash/i
                    payload = data
                    #helper.debug_write("\r\n#{payload[:to_translate]}\r\n")
                else
                    break if data == 0
                end
            end
        end
        
        it "should properly initialize a translation session" do
            re = @book.save!
            expect(re.to_s).to eql("true")
            
            re = helper.init_translation_session('Kirundi', 'Book', @data_model)
            expect(re).to_not be_nil
            db_table = re
            
            db_row = TrSession.first
            expect(db_row).to_not be_nil
            db_session = db_row.object
            expect(db_session.class.to_s).to match(/array/i)
            
            len = db_session.length
            0.upto(len-1) do |i|
                row = YAML::load(db_session[i])
                expect(row.class).to eql(db_table)
                #helper.debug_write("\r\n  #{row.attributes}\r\n")
            end           
        end
        
        it "should store/load a translation session successfully" do
            re = @book.save!
            expect(re.to_s).to eql("true")
            
            re = @slide.save!
            expect(re.to_s).to eql("true")
            
            payload = {}
            data = nil
            into_language = 'Kirundi'
            from_language = 'English'
            
            while data != 0
                data = helper.laaszen_translate(
                    from_language, into_language, payload, @data_model
                ) 
                expect(data).to_not be_nil
                if data.class.to_s =~ /hash/i
                    payload = data.merge(
                        translated: "TRANSLATION: #{data[:to_translate]}"
                    )
                    re = helper.store_translation_session(
                        into_language, payload, @data_model
                    )
                    expect(re).to_not be_nil
                else
                    break if data == 0
                end
            end
            
            ['Book', 'Slide'].each do |tb_name|
                rl_klass = Object.const_get(tb_name)
                expect(rl_klass).to_not be_nil
                
                tr_klass = load_translation_from_tr_session(into_language, tb_name)
                expect(tr_klass).to_not be_nil
                
                tr_attr = @data_model.get_model_net_attributes(tr_klass.new)
                rl_attr = @data_model.get_model_net_attributes(rl_klass.new)
                expect(tr_attr).to eql(rl_attr)
                
                tr_klass.all.each do |obj|
                    #helper.debug_write("\r\n=======\r\n#{obj.attributes}\r\n=======\r\n")
                end
            end
        end
        
        it "should translate, store/load translation to/from surrogate db table" do
            re = @book.save!
            expect(re.to_s).to eql("true")
            
            re = @slide.save!
            expect(re.to_s).to eql("true")
            
            payload = {}
            data = nil
            into_language = 'Kirundi'
            from_language = 'English'
            
            while data != 0
                data = helper.translate_and_persist(
                    from_language, into_language, payload, @data_model
                ) 
                expect(data).to_not be_nil
                if data.class.to_s =~ /hash/i
                    payload = data.merge(
                        translated: "TRANSLATION: #{data[:to_translate]}"
                    )
                else
                    break if data == 0
                end
            end
            
            bk_klass = helper.get_db_table_from_surrogate(
                'Book', into_language, @data_model
            )
            expect(bk_klass).to_not be_nil
            sl_klass = helper.get_db_table_from_surrogate(
                'Slide', into_language, @data_model
            )
            expect(sl_klass).to_not be_nil
            
            # loop mode of 'load_translated_payload_from_tr_session'
            ['Book', 'Slide'].each do |tb_name|
                tr_data = {}
                while tr_data != 0
                    tr_data = helper.edit_model_translation(
                        into_language, tb_name, tr_data, @data_model
                    )
                    expect(tr_data).to_not be_nil
                    if tr_data.class.to_s =~ /\Ahash\z/i
                        data  = tr_data[:payload][:translated]
                        #helper.debug_write("\r\n[#{tb_name}]\r\n#{data}\r\n")
                    else
                        break if tr_data == 0
                    end
                end
            end
            
            # load translation class mode
            ['Book', 'Slide'].each do |tb_name|
                re = helper.load_translated_payload_from_tr_session(
                    into_language, tb_name, {}, true
                )
                expect(re).to_not be_nil
                expect(re.class.to_s).to match(/\Aarray\z/i)
                tr_klass = re[0]
                expect(tr_klass).to_not be_nil
                
                tr_obj = tr_klass.first
                expect(tr_obj).to_not be_nil
                tr_attr = @data_model.get_model_net_attributes(tr_klass.new)
                expect(tr_attr).to_not be_nil
                
                helper.debug_write("\r\n\r\n#{'='*85}\r\n\r\n")
                
                tr_attr.each do |a|
                    data = tr_obj[a.to_sym]
                    helper.debug_write("\r\n[#{tb_name}.#{a}]\r\n#{data}\r\n")
                end
                
                helper.debug_write("\r\n\r\n#{'='*85}\r\n\r\n")
            end
            
            # functor mode
            ['Book', 'Slide'].each do |tb_name|
                helper.debug_write("\r\n\r\n#{'='*85}\r\n\r\n")
                
                re = helper.load_translated_payload_from_tr_session(
                    into_language, tb_name, {}, false, nil
                ) do |tr_payload|
                    data  = tr_payload[:payload][:translated]
                    helper.debug_write("\r\n[#{tb_name}]\r\n#{data}\r\n")
                end
                expect(re).to_not be_nil
                expect(re.class.to_s).to match(/\Aarray\z/i)
                
                helper.debug_write("\r\n\r\n#{'='*85}\r\n\r\n")
            end
        end
    end
    
    describe "LaaszenModel::SiteLanguage" do
        before(:each) do
            @site_language = LaaszenModel::SiteLanguage.new
        end
        
        after(:each) do 
            @data_model = @site_language.data_model
            helper.delete_dynamic_data_model(nil, @data_model) 
        end
        
        it "should set/get default language correctly" do
            re = helper.set_default_language
            expect(re).to_not be_nil
            re = helper.get_default_language
            expect(re).to_not be_nil
        end
        
        it "should set/get active language correctly" do
            cache = helper.get_site_cache
            expect(cache).to_not be_nil
            re = cache.set_cache_sentence('French', 'Igifaransa')
            expect(re).to_not be_nil
            
            active = 'Kirundi'
            re = helper.set_active_language(active)
            expect(re).to_not be_nil
            
            site_cache = cache.site_language_cache
            expect(site_cache).to eql({})
            
            re = helper.get_active_language
            expect(re).to_not be_nil
            active = re
            expect(active).to match(/\Akirundi\z/i)
            
            tr_str = cache.get_cache_sentence('French')
            expect(tr_str).to be_nil
            
            re = cache.set_cache_sentence('French', 'Igifaransa')
            expect(re).to_not be_nil
            tr_str = cache.get_cache_sentence('French')
            expect(tr_str).to_not be_nil
        end
        
        it "should set/get supported languages correctly" do
            langs = ['French', 'Swahili', 'Kirundi', 'Luganda'].sort
            langs.each do |l|
                re = helper.set_supported_languages(l)
                expect(re).to_not be_nil
            end
            re = helper.get_supported_languages
            expect(re).to_not be_nil
        end
        
        it "should return site key sentence suitably" do
            o_str = 'What the hell?'
            re = helper.sentence(o_str, @site_language)
            expect(re).to_not be_nil
            tr_str = @site_language.get_sentence_from_cache(o_str)
            expect(tr_str).to_not be_nil
        end
    end
end
