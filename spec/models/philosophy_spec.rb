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

require 'rails_helper'

RSpec.describe Philosophy, :type => :model do
    before(:each) do
        @attr = {
            language: 'English',
            theme: 'Man - Prospects of Immortality or Non-existence',
            part: 'Leadership as a Service (LaaS)',
            chapter: '5 Upper-bounded Scale of services',
            topic: 'Man does not serve but he trades services',
            subtopic: 'Does man serve Root?',
            content: 
            'Man is sovereign and cannot accept to be ruled.' +  
            'He can only accept a contract-based trade. Any attempt' +
            'to assume power over him triggers a repulsive effect' +
            'that is translated into political instabilities,' + 
            'upheavals, rebel movements, etc.'
        }
    end
    
        it "should require 'presence: non-empty, length: < 128' of 'language'" do
            philo = Philosophy.new(@attr.merge :language => '')
            expect(philo).to_not be_valid
            
            philo = Philosophy.new(@attr.merge :language => 'a'*129)
            expect(philo).to_not be_valid
        end
        
        it "should require 'presence: non-empty, length: < 1024' of 'theme'" do
            philo = Philosophy.new(@attr.merge :theme => '')
            expect(philo).to_not be_valid
            
            philo = Philosophy.new(@attr.merge :theme => 'a'*1025)
            expect(philo).to_not be_valid
        end
        
        it "should require 'length: < 1024' of 'part'" do
            philo = Philosophy.new(@attr.merge :part => 'a'*1025)
            expect(philo).to_not be_valid
        end
        
        it "should require 'presence, length, format' of 'chapter'" do
            philo = Philosophy.new(@attr.merge :chapter => '')
            expect(philo).to_not be_valid
            
            philo = Philosophy.new(@attr.merge :chapter => 'a'*1025)
            expect(philo).to_not be_valid
            
            chaps = ["1 some chapter", "another chapter", "12still another chapter"]
            idx = 0
            chaps.each do |c|
                philo = Philosophy.new(@attr.merge :chapter => c)
                if idx == 1 
                    expect(philo).to_not be_valid
                else 
                    expect(philo).to be_valid
                end
                idx += 1
            end
        end
        
        it "should require 'length: < 1024' of 'topic'" do
            philo = Philosophy.new(@attr.merge :topic => 'a'*1025)
            expect(philo).to_not be_valid
        end
        
        it "should require 'length: < 1024' of 'subtopic'" do
            philo = Philosophy.new(@attr.merge :subtopic => 'a'*1025)
            expect(philo).to_not be_valid
        end
        
        it "should require 'presence, length, unique' of 'content'" do
            philo = Philosophy.new(@attr.merge :content => '')
            expect(philo).to_not be_valid
            
            philo = Philosophy.new(@attr.merge :content => 'a'*(1024*1024+1))
            expect(philo).to_not be_valid
            
            Philosophy.create!(@attr)
            
            upcased = @attr[:content].upcase
            philo = Philosophy.new(@attr.merge :content => upcased)
            expect(philo).to_not be_valid
            
            philo = Philosophy.new(@attr)
            expect(philo).to_not be_valid
        end
end
