class PhilosophyController < ApplicationController
  def new
      @title = 'AddPhilo'
      @philosophy = Philosophy.new
  end
  
  def show
      @title = 'DisplayPhilo'
  end
end
