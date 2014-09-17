class SiteController < ApplicationController
  def index
    @papers = Paper.limit(10).order(published_at: :desc, reference: :desc)
  end
end
