class LegislativeTermController < ApplicationController
  before_action :find_body
  before_action :find_legislative_term

  def show
    redirect_to(body_feed_url(@body, format: :atom), status: :moved_permanently) if params[:format] == 'atom'

    @papers = @legislative_term.papers
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
    @legislative_term = @body.legislative_terms.find_by_term(params[:legislative_term].to_i)
  end
end
