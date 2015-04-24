#!/home/mwambaro/.rvm/rubies/ruby-2.2.0/bin/ruby

def usage(v)
    name = File.basename $0
    len = name.length
    us = "\r\nNAME" +
         "\r\n    #{name} - Script that generates CSS for prev/next arrows." +
         "\r\nSYNOPSIS" +
         "\r\n    #{name} [-h|--help] [-s|--suffix <SUFFIX>]" +
         "\r\n    #{' '*len} [-p|--path <PATH>]" +
         
         "\r\nDETAILS" +
         "\r\n    SUFFIX   : A unique suffix to append to generic identifiers." +
         "\r\n    PATH     : Full path to file where CSS code is to be written."
         "\r\n    Example  :" +
         "\r\n        #{name} -s ann -p css_code.css" + 
         
         "\r\nAUTHOR" +
         "\r\n    #{ENV['USER']}\r\n\r\n"
    puts us
    exit v     
end

def parse_cmd(argv)
    return nil if argv.nil?
    
    args_hash = nil
    
    len = argv.length-1
    0.upto(len) do |ii|
        if argv[ii] =~ /\A-h|--help\z/i
            usage(0)
        elsif argv[ii] =~ /\A-s|--suffix\z/i
            if ii+1 <= len
                args_hash ||= Hash.new
                args_hash[:suffix] = argv[ii+1]
            else
                usage(1)
            end
        elsif argv[ii] =~ /\A-p|--path\z/i
            if ii+1 <= len
                path = argv[ii+1]
                   
                if File.dirname(path) =~ /\A(\.+)\z/i
                    path = File.join(File.expand_path($1), path)
                end
                
                args_hash ||= Hash.new
                args_hash[:path] = path
            else
                usage(1)
            end
        else 
            usage(1)
        end
    end
    
    return args_hash
end

def gen_prev_next_navs(args_hash)
    return nil if args_hash.nil?
    return nil if args_hash.empty?
    return nil unless args_hash.key?(:suffix)
    return nil unless args_hash.key?(:path)
    
    @path = "#{args_hash[:path]}"
    @suffix = "_#{args_hash[:suffix]}"
    
    data = <<EOB

/* CSS */

#next#{@suffix},
#prev#{@suffix} {
    color: #333;
    display: inline-block;
    font: normal bold 2.5em Arial,sans-serif;
    overflow: hidden;
    position: relative;
    text-decoration: none;
    width: auto;
}

#next#{@suffix},
#prev#{@suffix} { padding: 0.5em 1.5em }

#next#{@suffix} { text-align: right }

#next#{@suffix}:before,
#next#{@suffix}:after,
#prev#{@suffix}:before,
#prev#{@suffix}:after {
    background: #333;
    -moz-border-radius: 0.25em;
    -webkit-border-radius: 0.25em;
    border-radius: 0.25em;
    content: "";
    display: block;
    height: 0.5em;
    position: absolute;
    right: 0;
    top: 50%;
    width: 1em;
}

#prev#{@suffix}:before,
#prev#{@suffix}:after { left: 0 }

#next#{@suffix}:before,
#prev#{@suffix}:before {
    -moz-transform: rotate(45deg);
    -ms-transform: rotate(45deg);
    -o-transform: rotate(45deg);
    -webkit-transform: rotate(45deg);
    transform: rotate(45deg);
}

#next#{@suffix}:after,
#prev#{@suffix}:after {
    -moz-transform: rotate(-45deg);
    -ms-transform: rotate(-45deg);
    -o-transform: rotate(-45deg);
    -webkit-transform: rotate(-45deg);
    transform: rotate(-45deg);
}

#prev#{@suffix}:after,
#next#{@suffix}:before { margin-top: -.36em }

#next#{@suffix}:hover,
#next#{@suffix}:focus,
#prev#{@suffix}:hover,
#prev#{@suffix}:focus { color: #006400; cursor: pointer; }

#next#{@suffix}:hover:before,
#next#{@suffix}:hover:after,
#next#{@suffix}:focus:before,
#next#{@suffix}:focus:after,
#prev#{@suffix}:hover:before,
#prev#{@suffix}:hover:after,
#prev#{@suffix}:focus:before,
#prev#{@suffix}:focus:after { background: #006400; cursor: pointer; }

/* container styles  */

nav { text-align: center }    
EOB
    
    return nil unless File.open(path, "wb"){|f| f.write(data)}
    
    return data
end

ret = gen_prev_next_navs(parse_cmd(ARGV))
ret = 1 if ret.nil?

exit ret
