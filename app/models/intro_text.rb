
class IntroText < ActiveRecord::Base 
    # mass assignment protection
    attr_accessor :language, :content
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
    def content=(value)
        self[:content] = value
    end
    def content
        self[:content]
    end
    # Other definitions
    def upload_intro_text=(data)
        self[:content] = data.read
    end
end
