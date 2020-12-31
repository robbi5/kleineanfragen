class BodyController < ApplicationController
  before_action :find_body

  def show
    @terms = @body.legislative_terms
    @scraper_result = @body.scraper_results.where.not(stopped_at: nil).order(stopped_at: :desc).first
    @latest_paper = @body.papers.where.not(published_at: nil).order(published_at: :desc).first
  end

  def feed
    @papers = @body.papers
              .where.not(published_at: nil)
              .order(published_at: :desc, reference: :desc)
              .page params[:page]
    fresh_when last_modified: @papers.maximum(:updated_at), public: true
    respond_to :atom # the only supported format
  end

  private

  def find_body
    @body = Body.friendly.find params[:body]
  end
end