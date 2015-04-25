# == Schema Information
#
# Table name: philosophies
#
#  id         :integer          not null, primary key
#  language   :string
#  theme      :string
#  part       :string
#  chapter    :string
#  topic      :string
#  subtopic   :string
#  content    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Philosophy < ActiveRecord::Base
    attr_accessor :language, :theme, :part, :chapter, 
                  :topic, :subtopic, :content
    regex = /\A\d+.+\z/i
    
    validates :language, presence: true, length: {maximum: 128}
    validates :theme, presence: true, length: {maximum: 1024}
    validates :part, length: {maximum: 1024}
    validates :topic, length: {maximum: 1024}
    validates :subtopic, length: {maximum: 1024}
    validates :chapter, presence: true, length: {maximum: 1024},
                        format: {with: regex}
    validates :content, presence: true, length: {maximum: 1024}
    validates_uniqueness_of :content, case_sensitive: false
    
    def philoup=(phi)
        data = phi.read
    end
    
    def language=(lang)
        self[:language] = lang
    end
    
    def language
        self[:language]
    end
    
    def theme=(th)
        self[:theme] = th
    end
    
    def theme
        self[:theme]
    end
    
    def part=(pt)
        self[:part] = pt
    end
    
    def part
        self[:part]
    end
    
    def chapter=(chap)
        self[:chapter] = chap
    end
    
    def chapter
        self[:chapter]
    end
    
    def topic=(tp)
        self[:topic] = tp
    end
    
    def topic
        self[:topic]
    end
    
    def subtopic=(stp)
        self[:subtopic] = stp
    end
    
    def subtopic
        self[:subtopic]
    end
    
    def content=(cn)
        data = cn.read
        self[:content] = data
    end
    
    def content
        self[:content]
    end    
end
