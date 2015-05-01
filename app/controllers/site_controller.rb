class SiteController < ApplicationController
  def index
    @bodies = Body.order(name: :asc).all
    @papers = Paper.where.not(published_at: nil).limit(10).order(published_at: :desc, reference: :desc)
    fresh_when last_modified: @papers.maximum(:updated_at), public: true
  end
end
