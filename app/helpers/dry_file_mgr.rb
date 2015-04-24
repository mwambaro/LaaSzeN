
module DryFileManagement
    ################################
    #   DRY file data management   #
    ################################
    
    ################################################
    #   Add these methods to your private space    #
    ################################################
    
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
    
    ########### end export methods #################
    
    # DRY file data management
    # hash = { pattern:, replacement:, all?: }
    # Basic support: find a pattern and replace it
    # rev_seq?: if both 'hash' and 'block' are defined
    #           the operations sequence defaults to:
    #           replacement using 'hash' data, then application of 'block'.
    #           To reverse this behavior, fix 'rev_seq?' to true
    # Note: Data is handed to your block as binaries. This allows us to handle
    #       files of different types of data without making unnecessary assumptions.
    
    class FileDryMgr
        attr_reader :data
        
        def initialize(file, hash={}, rev_seq=false)
            @file = file
            @hash = hash
            @max_cb_read = 1.megabyte
            @r_sequence = rev_seq
            @data = nil
        end
        
        def FileDryMgr.valid_file?(file)
            return false unless FileDryMgr.valid_string?(file)
            if File.directory?(file)
                return false unless Dir.exists?(file)
            else
                return false unless File.exists?(file)
                return false if File.zero?(file)
            end
            true
        end
        
        def FileDryMgr.valid_string?(str)
            return false if str.nil?
            return false unless str.class.to_s =~ /\Astring\z/i
            return false if str.empty?
            return false if str.blank?
            true
        end 
        
        def FileDryMgr.valid_hash?(h, presence_of_values=true)
            return false if h.nil?
            return false unless h.class.to_s =~ /\Ahash\z/i
            return false if h.empty?
            if presence_of_values
                h.values.each do |v|
                    return false if v.nil?
                    return false if v.to_s.empty?
                end
            end
            true
        end
        
        def FileDryMgr.valid_array?(a)
            return false if a.nil?
            return false unless a.class.to_s =~ /\Aarray\z/i
            return false if a.length == 0
            true
        end
        
        def FileDryMgr.s_to_binaries(str)
            return nil if str.nil?
            return nil if str.empty?
            bin_obj = ActiveRecord::Type::Binary.new
            bin_obj.type_cast(str)
        end
        
        def FileDryMgr.camelcase(snakecased)
            return nil if snakecased.nil?
            return nil if snakecased.empty?
            
            mod = snakecased
            camel_cased = nil
            
            while m = mod.match(/_([a-z])/i)
                camel_cased ||= ""
                pre = m.pre_match
                post = m.post_match
                # ignore first letter 
                if pre != "" #valid_string?(pre)    
                    camel_cased += "#{pre}#{m[1].upcase}"
                else
                    camel_cased += "_#{m[1]}"
                end
                mod = post 
            end
            
            return snakecased if camel_cased.nil?
            camel_cased += mod unless mod.nil?
            
            return camel_cased
        end
        
        def FileDryMgr.snakecase(camelcased)
            return nil if camelcased.nil?
            return nil if camelcased.empty?
            
            mod = camelcased
            snake_cased = nil
            
            while m = mod.match(/([A-Z])/)
                snake_cased ||= ""
                pre = m.pre_match
                post = m.post_match
                # ignore first letter 
                if pre != "" #valid_string?(pre)    
                    snake_cased += "#{pre}_#{m[1].downcase}"
                else
                    snake_cased += "#{m[1]}"
                end
                mod = post 
            end
            snake_cased += mod
            snake_cased = snake_cased.downcase
            
   
            return snake_cased
        end
        
        def deserialize_hash(serialized_hash)
            return nil
        end
        
        def copy_to(file)
            return nil if !FileDryMgr.valid_string?(file)
            handle_file_data do |data|
                File.open(file, "wb"){|f| f.write(data)}
            end    
        end
        
        def compare_to(file)
            return false if !FileDryMgr.valid_file?(file)
            handle_file_data do |d1|
                fo = FileDryMgr.new(file)
                re = fo.handle_file_data do |d2|
                    (!d1.nil? && !d2.nil?) && (d1.to_s == d2.to_s)
                end
                re
            end 
        end
        
        def handle_file_data
            return nil if !FileDryMgr.valid_file?(@file)
            
            ret = nil
            rep_ret = false
        
            File.open(@file, "rb") do |f|
                size = f.size
                cb = size > @max_cb_read ? @max_cb_read : size
                tdata = ""
                while !tdata.nil? 
                    begin      
                        tdata = f.sysread(cb)
                    rescue
                        break
                    else
                        break if tdata.nil?
                        @data = tdata
                        if !@r_sequence
                            rep_ret = replace_data
                            return(ret = (yield @data)) if block_given?
                        else
                            ret = (yield @data) if block_given?
                            rep_ret = replace_data
                            return(ret)
                        end
                    end
                end
            end
            return ret if block_given?
            return rep_ret
        end
        
        def handle_file_data(&block)
            return nil if !FileDryMgr.valid_file?(@file)
            
            ret = nil
            rep_ret = false
        
            File.open(@file, "rb") do |f|
                size = f.size
                cb = size > @max_cb_read ? @max_cb_read : size
                tdata = ""
                while !tdata.nil? 
                    begin      
                        tdata = f.sysread(cb)
                    rescue
                        break
                    else
                        break if tdata.nil?
                        @data = tdata
                        if !@r_sequence
                            rep_ret = replace_data
                            return(ret = (block.call @data)) unless block.nil?
                        else
                            ret = (block.call @data) unless block.nil?
                            rep_ret = replace_data
                            return(ret)
                        end
                    end
                end
            end
            return ret unless block.nil?
            return rep_ret
        end
        
        def data
            @data
        end
        
        private
    
        def replace_data
            return nil if @data.nil?
            return nil if !hash_data?
                
            p = @hash[:pattern]
            r = @hash[:replacement]
            a = @hash[:all?]
            data_s = @data.to_s
            mdata = nil
            while match = data_s.match(/#{p}/)
                mdata ||= ""
                mdata += match.pre_match + r
                data_s = match.post_match
                break if !a
            end
            if !mdata.nil?
                mdata += data_s
                @data = FileDryMgr.s_to_binaries(mdata)
            end
            self
        end
        
        def hash_data?
            keys = [:pattern, :replacement, :all?]
            ret = false
            vals = @hash.values
            vals_bl = false
            vals_bl = (
                vals[0] != "" && vals[1] != "" && 
                (vals[2] == false || vals[2] == true)
            ) if vals.length >= 3
            hash_bl = (!@hash.nil? && !@hash.empty? && @hash.keys == keys)
            ret = true if  hash_bl == true && vals_bl == true
            return ret
        end
        
        def hash_empty?
            return @hash.empty? if !@hash.nil?
            true
        end
    end
    
    class BackupFile
        attr_accessor :data
        def initialize(file)
            @file = file
            @bfile = backup_name(file)
            @data = nil
        end
    
        def backup
            file = self.file
            return nil if file.nil?
            return nil if file.empty?
            return nil if file =~ /\A\s+\z/i
            return nil if !File.exists?(file)
            da = nil
            File.open(file, "rb") do |f|
                da = f.read   
            end
            @data = da
            bfile = self.bfile
            File.open(bfile, "wb") do |f|
                f.write(da)  
            end
            da
        end
    
        def recover
            file = self.file
            return nil if file.nil?
            return nil if file.empty?
            return nil if file =~ /\A\s+\z/i
            return nil if !File.exists?(file)
            bfile = self.bfile
            data = nil
            File.open(bfile, "rb") do |f|
                data = f.read   
            end
            File.open(file, "wb") do |f|
                f.write(data)  
            end
            File.delete(self.bfile)
            data
        end
        
        def data=(d)
            @data = d
        end
        def data
            @data
        end
        
        def bfilename=(f)
            @bfile = f
        end
        def bfilename
            @bfile
        end
    
        protected
    
        def file=(f)
            @file = f
        end
        def file
            @file
        end
    
        def bfile=(bf)
            @bfile = bf
        end
        def bfile
            @bfile
        end
    
        def backup_name(file)
            return nil if file.nil?
            return nil if file.empty?
            return nil if file =~ /\A\s+\z/i
            p = file.split(".")
            ext = p[p.length-1]
            fi = ""
            if p.length > 1
                f = p[0...p.length-1]
                f.each do |ff|
                   fi += ff
                end
                fi += '.up.' + ext
            else
                fi = ext + '.up'
            end
            fi
        end
    end
end
