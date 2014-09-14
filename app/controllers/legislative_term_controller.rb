class LegislativeTermController < ApplicationController
  before_filter :find_body
  before_filter :find_legislative_term

  def show
    @papers = @body.papers.where(legislative_term: @legislative_term).order(published_at: :desc, reference: :desc)
  end

  def find_body
    @body = Body.friendly.find params[:body]
  end

  def find_legislative_term
    @legislative_term = params[:legislative_term].to_i
  end
end
