
module HtmlRotator
    class Rotator
        def make_rotator_html(array, tag='p')
            return nil if array.nil?
    
            html = "<div id=\"container\">" +
               "<div id=\"rotator_wrapper\">" +
               "<ul id=\"rotator\">"
            count = 1
    
            array.each do |ary|
                html += "<li id=\"photo_#{count}\"><#{tag}>" + ary + "</#{tag}></li>"
                count += 1
            end
    
            html += "</ul>" +
                "<a href=\"#\" id=\"rotator_play_pause\">PAUSE</a>" +
                "</div>" +
                "</div>"
            
            return html
        end

        def define_html_rotator(array, partial_full_path)
            code = make_rotator_html(array)
            
            name = File.basename(partial_full_path)
            partial = name.match(/_(.+).html.erb/i)  
            return nil if partial.nil?
            
            name = partial[1]         
            
            File.open(partial_full_path, "wb"){|f| f.write(code)}
            
            return name
        end
    end
end
