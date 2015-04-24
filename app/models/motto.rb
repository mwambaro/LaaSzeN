
class Motto < ActiveRecord::Base 
    # mass assignment protection
    attr_accessor :language, :name, :content
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
    def name=(value)
        self[:name] = value
    end
    def name
        self[:name]
    end
    def content=(value)
        self[:content] = value
    end
    def content
        self[:content]
    end
    # Other definitions
    def upload_motto=(data)
        self[:content] = data.read
    end
end
