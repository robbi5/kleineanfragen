class LoadPaperDetailsJob < PaperJob
  queue_as :meta

  OVERWRITEABLE = [:originators, :answerers, :doctype, :url]

  def perform(paper)
    return unless paper.body.scraper.const_defined? :Detail

    logger.info "Loading details for Paper [#{paper.body.state} #{paper.full_reference}]"
    scraper = paper.body.scraper::Detail.new(paper.legislative_term, paper.reference)
    logger.progname = "LoadPaperDetailsJob #{paper.body.state}"
    scraper.logger = logger

    results = scraper.scrape

    if results.nil?
      logger.warn 'Detail Scraper for Paper [#{paper.body.state} #{paper.full_reference}] got nothing'
      return
    end

    results.each do |key, value|
      paper.send("#{key}=", value) if paper.send(key).blank? || OVERWRITEABLE.include?(key)
    end

    if !paper.valid?
      logger.warn "[#{paper.body.state}] Can't save Paper [#{paper.full_reference}] - #{paper.errors.messages}"
      return
    end

    url_change = paper.url_changed?

    paper.save!
    StorePaperPDFJob.perform_later(paper, force: true) if url_change && !paper.url.blank?
  end
end