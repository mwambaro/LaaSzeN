
module LaaszenCacheStore
    class SiteCache 
        def initialize(time)
            @time_i = time
            @site_language_cache = Hash.new
            @active = 'English'
            @object = Hash.new
            @count = 0
        end
        
        def start_session(s_key=nil)
            if s_key.nil?
                s_key = @count.to_s.to_sym
                if @object.key?(s_key)
                    @count += 1
                    s_key = @count.to_s.to_sym
                end
                @object[s_key] = {}
            else
                unless @object.key?(s_key)
                    @object[s_key] = {}
                end
            end
            
            return s_key
        end
        
        def end_session(s_key)           
            unless s_key.nil?
                return delete_object(s_key)
            end
            return nil
        end
        
        def set_object(s_key, key, val)
            return nil unless valid_string?(s_key)
            return nil unless valid_string?(key)
            
            unless @object.key?(s_key.to_sym)
                return nil
            end
            
            @object[s_key.to_sym] ||= Hash.new
            @object[s_key.to_sym][key.to_sym] = val
            
            return s_key, key
        end
        
        def get_object(s_key, key)
            return nil unless valid_string?(s_key)
            return nil unless valid_string?(key)
            
            unless @object.key?(s_key.to_sym)
                return nil
            end
            obj = @object[s_key.to_sym]
            
            unless obj.key?(key.to_sym)
                return nil
            end
            
            return @object[s_key.to_sym][key.to_sym]
        end
        
        def delete_object(s_key)
            return false unless valid_string?(s_key)
            
            unless @object.key?(s_key.to_sym)
                return true
            end

            return @object.delete(s_key.to_sym).nil?
        end
        
        def set_active_language(a)
            @active = a
        end
        
        def get_active_language
            @active
        end
        
        def site_language_cache
            @site_language_cache
        end
        
        def reset_site_language_cache
             @site_language_cache = Hash.new
             @active = nil
        end
    
        def set_cache_sentence(o_sentence, tr_sentence)
            return nil unless valid_string?(o_sentence)
            return nil unless valid_string?(tr_sentence)
            return nil if @site_language_cache.nil?
            
            str = nil
            
            unless @active.nil?
                begin
                    @site_language_cache.merge!({
                        "#{o_sentence}" => tr_sentence
                    })
                    str = tr_sentence
                rescue
                    nothing = nil
                end
            end
        
            return str 
        end
    
        def get_cache_sentence(o_sentence)
            return nil unless valid_string?(o_sentence)
            return nil if @site_language_cache.nil?
            return nil if @site_language_cache.empty?
            return nil unless @site_language_cache.key?(o_sentence)
            
            str = nil
            
            unless @active.nil?
                str = @site_language_cache[o_sentence]
            end
            
            return str
        end
    
        private
        
        def string_valid?(str)
            valid_string?(str)
        end
        
        def valid_string?(str)
            return false if str.nil?
            return false unless str.class.to_s =~ /\Astring|symbol\z/i
            return false if str.empty?
            return false if str.blank?
            true
        end
    end
end
