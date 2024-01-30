class AnimationsController < ApplicationController
  def create
    AnimationAdder.new(params[:fbx], params[:actions], params[:scene]).call
    redirect_to root_path
  end
end
