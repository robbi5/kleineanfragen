class LoadPaperDetailsJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    return unless paper.body.scraper.const_defined? :Detail

    Rails.logger.info "Loading details for Paper [#{paper.body.state} #{paper.full_reference}]"
    detail = paper.body.scraper::Detail.new(paper.legislative_term, paper.reference).scrape

    # FIXME: should iterate over detail, fill anything that is nil in paper

    paper.originators = detail[:originators]
    paper.save
  end
end