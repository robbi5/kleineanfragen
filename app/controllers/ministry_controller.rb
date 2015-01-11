class MinistryController < ApplicationController
  before_filter :find_body
  before_filter :find_ministry

  def show
    @papers = @ministry.papers
              .order(legislative_term: :desc, published_at: :desc, reference: :desc)
              .page params[:page]
    fresh_when last_modified: @papers.maximum(:updated_at), public: true
  end

  private

  def find_body
    @body = Body.friendly.find params[:body]
  end

  def find_ministry
    @ministry = Ministry.where(body: @body).friendly.find params[:ministry]
  end
end
