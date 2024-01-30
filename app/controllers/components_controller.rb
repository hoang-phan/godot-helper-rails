class ComponentsController < ApplicationController
  def create
    ComponentAdder.new(params[:component], params[:scene]).call
    redirect_to root_path
  end
end
