class RootsController < ApplicationController
  def update
    Rails.cache.write "#{params[:id]}_path", params.require(:root).permit(:path)[:path]
    head :ok
  end
end
