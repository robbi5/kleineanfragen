class BodyController < ApplicationController
  before_filter :find_body

  def show
    @terms = Paper.where(body: @body).group(:legislative_term).count.to_a.sort.reverse
  end

  private

  def find_body
    @body = Body.friendly.find params[:body]

    # Add support for renamed slugs
    return redirect_to @body, status: :moved_permanently if request.path != body_path(@body)
  end
end
