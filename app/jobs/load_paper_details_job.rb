class LoadPaperDetailsJob < ActiveJob::Base
  queue_as :meta

  OVERWRITEABLE = [:originators, :answerers]

  def perform(paper)
    return unless paper.body.scraper.const_defined? :Detail

    Rails.logger.info "Loading details for Paper [#{paper.body.state} #{paper.full_reference}]"
    detail = paper.body.scraper::Detail.new(paper.legislative_term, paper.reference).scrape

    detail.each do |key, value|
      paper.send("#{key}=", value) if paper.send(key).blank? || OVERWRITEABLE.include?(key)
    end

    paper.save
  end
end