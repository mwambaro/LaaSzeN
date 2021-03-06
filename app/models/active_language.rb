
class ActiveLanguage < ActiveRecord::Base 
    # mass assignment protection
    attr_accessor :language, :active, :default, :supported
    # Associations macro-style method invocations
    # Validations
    validates_format_of :supported, :with => /\A[\d\w]+(#[\d\w]+)*\z/i
    # Callbacks
    # Accessors overloading
    def language=(value)
        self[:language] = value
    end
    def language
        self[:language]
    end
    def active=(value)
        self[:active] = value
    end
    def active
        self[:active]
    end
    def default=(value)
        self[:default] = value
    end
    def default
        self[:default]
    end
    def supported=(value)
        self[:supported] = value
    end
    def supported
        self[:supported]
    end
    # Other definitions
end
