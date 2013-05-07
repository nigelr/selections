class SelectionsController < ApplicationController
  before_filter :parent_finder

  def index
    if @parent
      @selections = @parent.children
    else
      @selections = Selection.roots
    end
  end

  def new
    @selection = @parent.children.new
  end

  def edit
    @selection = @parent.children.find(params[:id])
  end

  def create
    @selection = @parent.children.new(params[:selection])

    if @selection.save
      redirect_to selection_selections_path(@parent), notice: 'Selection was successfully created.'
    else
      render action: 'new'
    end
  end

  def update
    @selection = Selection.find(params[:id])

    if @selection.update_attributes(params[:selection])
      redirect_to selection_selections_path(@parent), notice: 'Selection was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @selection = Selection.find(params[:id])
    @selection.destroy

    redirect_to selections_url
  end

  private
  def parent_finder
    @parent = Selection.find_by_id(params[:selection_id])
  end
end
