class IntroTextsController < ApplicationController
  before_action :set_intro_text, only: [:show, :edit, :update, :destroy]

  # GET /intro_texts
  # GET /intro_texts.json
  def index
    @intro_texts = IntroText.all
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # GET /intro_texts/1
  # GET /intro_texts/1.json
  def show
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # GET /intro_texts/new
  def new
    @intro_text = IntroText.new
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # GET /intro_texts/1/edit
  def edit
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # POST /intro_texts
  # POST /intro_texts.json
  def create
    @intro_text = IntroText.new(intro_text_params)

    respond_to do |format|
      if @intro_text.save
        format.html { redirect_to @intro_text, notice: 'Intro text was successfully created.' }
        format.json { render :show, status: :created, location: @intro_text }
      else
        format.html { render :new }
        format.json { render json: @intro_text.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /intro_texts/1
  # PATCH/PUT /intro_texts/1.json
  def update
    respond_to do |format|
      if @intro_text.update(intro_text_params)
        format.html { redirect_to @intro_text, notice: 'Intro text was successfully updated.' }
        format.json { render :show, status: :ok, location: @intro_text }
      else
        format.html { render :edit }
        format.json { render json: @intro_text.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /intro_texts/1
  # DELETE /intro_texts/1.json
  def destroy
    @intro_text.destroy
    respond_to do |format|
      format.html { redirect_to intro_texts_url, notice: 'Intro text was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_intro_text
      @intro_text = IntroText.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def intro_text_params
      params.require(:intro_text).permit(:language, :upload_intro_text)
    end
    
    def get_view_path(params)
        return nil if params.nil?
        DavidEgan.new.get_view_path(params)
    end
end
