class SiteController < ApplicationController
  def index
    @bodies = Body.order(name: :asc).all
    @papers = Paper
              .where.not(published_at: nil)
              .limit(10)
              .includes(:body, :paper_originators)
              .order(published_at: :desc, reference: :desc)
    @count = Paper.count.round(-1)
    fresh_when last_modified: @papers.maximum(:updated_at), public: true
  end

  def status
    expires_now
    render plain: "OK - #{Time.now}"
  end
end
