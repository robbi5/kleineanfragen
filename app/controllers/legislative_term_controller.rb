class LegislativeTermController < ApplicationController
  before_filter :find_body
  before_filter :find_legislative_term

  def show
    redirect_to(body_feed_url(@body, format: :atom), status: :moved_permanently) if params[:format] == 'atom'

    @papers = @body.papers
              .where(legislative_term: @legislative_term)
              .where.not(published_at: nil)
              .includes(:body, :paper_originators)
              .order(published_at: :desc, reference: :desc)
              .page params[:page]
    fresh_when last_modified: @papers.maximum(:updated_at), public: true
  end

  private

  def find_body
    @body = Body.friendly.find params[:body]
  end

  def find_legislative_term
    @legislative_term = params[:legislative_term].to_i
  end
end
