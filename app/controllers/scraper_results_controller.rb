class ScraperResultsController < ApplicationController
  before_action :find_scraper_result, only: [:show]

  def index
    @bodies = Body.all
    @results = {}
    @dates = ((Date.today - 10.days)..Date.today).to_a
    @bodies.each do |body|
      scraper_results = body.scraper_results.where(['created_at > ?', @dates.first]).order(created_at: :asc)
      @results[body.id] = @dates.map { |d| [d, scraper_results.select { |r| r.created_at.to_date == d }] }.to_h
    end
  end

  def show
    render json: @result
  end

  private

  def find_scraper_result
    @result = ScraperResult.find_by_hash(params[:scraper_result])
  rescue
    render status: 404
  end
end
