class BodyController < ApplicationController
  before_filter :find_body

  def show
  end

  def find_body
    @body = Body.friendly.find params[:body]

    # Add support for renamed slugs
    if request.path != body_path(@body)
      return redirect_to @body, :status => :moved_permanently
    end
  end
end
