class ScraperResultsController < ApplicationController
  before_action :find_scraper_result, only: [:show]

  def index
    @bodies = Body.all
    @results = {}
    @bodies.each do |body|
      @results[body.id] = body.scraper_results.order(created_at: :desc).limit(10).reverse
    end

    @dates = @results.map { |_, results| results.map { |result| result.created_at.to_date } }.flatten.sort.uniq
    @results.each do |body_id, results|
      grouped = @dates.map { |d| [d, results.select { |r| r.created_at.to_date == d }] }.to_h
      @results[body_id] = grouped
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
