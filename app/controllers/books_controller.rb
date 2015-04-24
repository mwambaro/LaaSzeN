class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy]

  # GET /books
  # GET /books.json
  def index
    @books = Book.all
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # GET /books/1
  # GET /books/1.json
  def show
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end
  
  def book_shelf
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end
  
  def book_whole
    @books = Book.all
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end
  
  def book_collapse
    @books = Book.all
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # GET /books/new
  def new
    @book = Book.new
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # GET /books/1/edit
  def edit
    @view_path = get_view_path(params)
    DavidEgan.new.make_dav_layout_compatible(@view_path)
  end

  # POST /books
  # POST /books.json
  def create
    @book = Book.new(book_params)

    respond_to do |format|
      if @book.save
        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render :show, status: :created, location: @book }
      else
        format.html { render :new }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    respond_to do |format|
      if @book.update(book_params)
        format.html { redirect_to @book, notice: 'Book was successfully updated.' }
        format.json { render :show, status: :ok, location: @book }
      else
        format.html { render :edit }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book.destroy
    respond_to do |format|
      format.html { redirect_to books_url, notice: 'Book was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_book
      @book = Book.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def book_params
      params.require(:book).permit(:language, :theme, :author, :upload_book)
    end
    
    def get_view_path(params)
        return nil if params.nil?
        DavidEgan.new.get_view_path(params)
    end
end
