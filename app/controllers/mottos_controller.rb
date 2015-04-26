class MottosController < ApplicationController
  before_action :set_motto, only: [:show, :edit, :update, :destroy]

  # GET /mottos
  # GET /mottos.json
  def index
    @mottos = Motto.all
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # GET /mottos/1
  # GET /mottos/1.json
  def show
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # GET /mottos/new
  def new
    @motto = Motto.new
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # GET /mottos/1/edit
  def edit
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # POST /mottos
  # POST /mottos.json
  def create
    @motto = Motto.new(motto_params)

    respond_to do |format|
      if @motto.save
        format.html { redirect_to @motto, notice: 'Motto was successfully created.' }
        format.json { render :show, status: :created, location: @motto }
      else
        format.html { render :new }
        format.json { render json: @motto.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /mottos/1
  # PATCH/PUT /mottos/1.json
  def update
    respond_to do |format|
      if @motto.update(motto_params)
        format.html { redirect_to @motto, notice: 'Motto was successfully updated.' }
        format.json { render :show, status: :ok, location: @motto }
      else
        format.html { render :edit }
        format.json { render json: @motto.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mottos/1
  # DELETE /mottos/1.json
  def destroy
    @motto.destroy
    respond_to do |format|
      format.html { redirect_to mottos_url, notice: 'Motto was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_motto
      @motto = Motto.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def motto_params
      params.require(:motto).permit(:language, :name, :upload_motto)
    end
    
    def get_view_path(params)
        return nil if params.nil?
        DavidEgan.new.get_view_path(params)
    end
end
