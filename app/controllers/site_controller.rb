class SiteController < ApplicationController
  def index
    @bodies = Body.order(name: :asc).all
    @papers = Paper.limit(10).order(published_at: :desc, reference: :desc)
  end
end
