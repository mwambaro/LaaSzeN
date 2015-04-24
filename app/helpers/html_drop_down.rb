

module HtmlDropDown
    class DropDown
        def prefix(n, k=nil)
            m = n < 0 ? -n : n
            p = k.nil? ? 1 : k
            p = p < 0 ? -p : p
            pref = m > 0 ? "\r\n"*p + " "*m : "\r\n"
        end
        
        def valid_string?(str)
            return false if str.nil?
            return false unless str.class.to_s =~ /\Astring\z/i
            return false if str.empty?
            return false if str =~ /\A\s+\z/
            true
        end 

        def sentence(str, bl_add_sentence_method=false)
            return "" unless valid_string?(str)
            
            p_str = "#{str}"
            
            if bl_add_sentence_method
                p_str = "sentence(#{str})"
            end
            
            return p_str
        end

        def brace(opt, bl_op=true)
            op = bl_op == true ? "{" : "}"
            
            op = "" unless valid_string?(opt)
            op = "" if opt =~ /\Anil|null\z/i
            
            return op
        end
        
        # orientation: down | up
        def gen_drop_down_ex(
            hash, max_menus, bl_erb=true, bl_sentence=false, orientation='down'
        )
            return nil if hash.nil?
            return nil if hash.empty?
            html = nil
            
            unless ::Rails.env =~ /\Aproduction\z/i
                DropDownId.all.each{|m| m.destroy} if DropDownId.count >= max_menus
            end
            count = DropDownId.count + 1
            menu_bar_length = 0
            
            op_erb = "<%="
            cl_erb = "%>"
            
            unless bl_erb
                op_erb = ""
                cl_erb = ""
            end
            
            dl_class = "dropdown"
            dt_class = "ddheader"
            dd_class = "ddcontent"
            div0_class = "dd_box"
            div1_class = "div_dd_box"
            p_class = "pheader"
    
            hash.each do |k,v|
                next if v.nil? || k.nil?
                
                menu_bar_length += 1
                
                dl_id = "dl#{count}"
                td_id = "td#{count}"
                dt_id = "dt#{count}"
                dd_id = "dd#{count}"
                p_id  = "p#{count}"
                
                ddh = {
                    dt: dt_id,
                    dd: dd_id
                }
                DropDownId.create(ddh)
                
                if orientation =~ /\Adown\z/i
                    html ||= ""
                    html += prefix(4) + "<ul id=\"#{dl_id}\" class=\"#{dl_class}\">" +
                            prefix(8) + "<li id=\"#{dt_id}\" class=\"#{dt_class}\">" +
                            prefix(12) + "<a>" + 
                            prefix(16) + "#{op_erb} "+
                                    "#{sentence(k.chomp, bl_sentence)} "+
                                    "#{cl_erb}" +
                            prefix(12) + "</a>" +
                            prefix(12) + "<ul id=\"#{dd_id}\" class=\"#{dd_class}\">"
                    v.each do |item|
                        html += prefix(16) + "<li>" +
                                prefix(20) + "#{op_erb} " +
                                         "#{sentence(item.chomp, bl_sentence)} " +
                                         "#{cl_erb}" +
                                prefix(16) + "</li>"           
                    end 
                    html += prefix(12) + "</ul>" +
                        prefix(8) + "</li>" +
                        prefix(4) + "</ul>"
                elsif orientation =~ /\Aup\z/i # up
                    html ||= ""
                    html += prefix(4) + "<ul id=\"#{dl_id}\" class=\"#{dl_class}\">" +
                            prefix(8) + "<li id=\"#{dt_id}\" class=\"#{dt_class}\">" +
                            prefix(12) + "<ul id=\"#{dd_id}\" class=\"#{dd_class}\">"
                    v.each do |item|
                        html += prefix(16) + "<li>" +
                                prefix(20) + "#{op_erb} " +
                                         "#{sentence(item.chomp, bl_sentence)} " +
                                         "#{cl_erb}" +
                                prefix(16) + "</li>"           
                    end 
                    html += prefix(12) + "</ul>" +
                            prefix(12) + "<a>" + 
                            prefix(16) + "#{op_erb} "+
                                    "#{sentence(k.chomp, bl_sentence)} "+
                                    "#{cl_erb}" +
                            prefix(12) + "</a>" +
                            prefix(8) + "</li>" +
                            prefix(4) + "</ul>"
                end
                count += 1
            end
            
            tb_id_num = (max_menus/menu_bar_length).floor
            div_id = "div#{tb_id_num}"
    
            htm = prefix(0) + 
                  "<div align=\"center\" class=\"#{div0_class}\">" +
                  "<div id=\"#{div_id}\" align=\"center\" class=\"#{div1_class}\">" +
                  html + prefix(0) + 
                  "</div></div>" # + prefix(0) + "<div style=\"clear:both\" />"
        end

        # hash: is an {'menu title' => [array of menu items]} data structure
        # E.g {"Entry 1"=>["Menu 1", " Menu 2"], "Entry 2"=>["Menu 3", "Menu 4"]}
        # max_menus: max number of menus in the whole site.
        # bl_erb: true if code should be enclosed in "<%= %>", used to generate
        #         code that should be pasted directly in a view. False otherwise,
        #         used for code that lies outside views so it can be evaluated.
        # bl_sentence: true if each visible string is to be wrapped by 'sentence'
        #              helper function. false otherwise
        # N.B: Convention over configuration:
        #          * dl_class = "dropdown"
        #            dt_class = "ddheader"
        #            dd_class = "ddcontent"
        #            div_class = "div_dd_box"
        #            table_class = "dd_box"
        #          *Ids are made by a tag concatenated with an 
        #            ordinal number 0 < n <= max_menus. Only table, td, dt, and dd have ids.
        
        def gen_drop_down(hash, max_menus, bl_erb=true, bl_sentence=false)
            return nil if hash.nil?
            return nil if hash.empty?
            html = nil
            
            unless ::Rails.env =~ /\Aproduction\z/i
                DropDownId.all.each{|m| m.destroy} if DropDownId.count >= max_menus
            end
            count = DropDownId.count + 1
            menu_bar_length = 0
            
            op_erb = "<%="
            cl_erb = "%>"
            
            unless bl_erb
                op_erb = ""
                cl_erb = ""
            end
            
            dl_class = "dropdown"
            dt_class = "ddheader"
            dd_class = "ddcontent"
            div0_class = "dd_box"
            div1_class = "div_dd_box"
            p_class = "pheader"
    
            hash.each do |k,v|
                next if v.nil? || k.nil?
                
                menu_bar_length += 1
                
                dl_id = "dl#{count}"
                td_id = "td#{count}"
                dt_id = "dt#{count}"
                dd_id = "dd#{count}"
                p_id  = "p#{count}"
                
                ddh = {
                    dt: dt_id,
                    dd: dd_id
                }
                DropDownId.create(ddh)
                
                html ||= ""
                html += prefix(4) + "<dl id=\"#{dl_id}\" class=\"#{dl_class}\">" +
                        prefix(8) + "<dt id=\"#{dt_id}\" class=\"#{dt_class}\">" +
                        prefix(12) + "<p id=\"#{p_id}\" class=\"#{p_class}\">" + 
                                     "#{op_erb} "+
                                    "#{sentence(k.chomp, bl_sentence)} "+
                                    "#{cl_erb}" +
                        prefix(8) + "</p></dt>" +
                        prefix(8) + "<dd id=\"#{dd_id}\" class=\"#{dd_class}\">" +
                        prefix(12) + "<ul>"
                v.each do |item|
                    html += prefix(16) + "<li>" +
                            prefix(20) + "#{op_erb} " +
                                         "#{sentence(item.chomp, bl_sentence)} " +
                                         "#{cl_erb}" +
                            prefix(16) + "</li>"           
                end 
                html += prefix(12) + "</ul>" +
                        prefix(8) + "</dd>" +
                        prefix(4) + "</dl>"
                count += 1
            end
            
            tb_id_num = (max_menus/menu_bar_length).floor
            div_id = "div#{tb_id_num}"
    
            htm = prefix(0) + 
                  "<div align=\"center\" class=\"#{div0_class}\">" +
                  "<div id=\"#{div_id}\" align=\"center\" class=\"#{div1_class}\">" +
                  html + prefix(0) + 
                  "</div></div>" # + prefix(0) + "<div style=\"clear:both\" />"
        end
        
        # hash: see comments above 'gen_drop_down' method.
        # options: see comments above 'gen_drop_down' method.
        # Return: nil/[klass_object, method_name]
        def define_html_drop_down_class(
            hash, max_menus, partial_full_path, orientation='down'
        )
            code = gen_drop_down_ex(hash, max_menus, true, false, orientation)
            
            name = File.basename(partial_full_path)
            partial = name.match(/_(.+).html.erb/i)  
            return nil if partial.nil?
            
            name = partial[1]         
            
            File.open(partial_full_path, "wb"){|f| f.write(code)}
            
            return name
        end
    end
end
