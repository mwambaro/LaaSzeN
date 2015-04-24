
class Slide < ActiveRecord::Base 
    # mass assignment protection
    attr_accessor :language, :author, :topic, :content
    # Associations macro-style method invocations
    # Validations
    # Callbacks
    # Accessors overloading
    def language=(value)
        self[:language] = value
    end
    def language
        self[:language]
    end
    def author=(value)
        self[:author] = value
    end
    def author
        self[:author]
    end
    def topic=(value)
        self[:topic] = value
    end
    def topic
        self[:topic]
    end
    def content=(value)
        self[:content] = value
    end
    def content
        self[:content]
    end
    # Other definitions
    def upload_slide=(data)
        self[:content] = data.read    
    end
end
