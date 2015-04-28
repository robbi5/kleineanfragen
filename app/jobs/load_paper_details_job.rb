class LoadPaperDetailsJob < PaperJob
  queue_as :meta

  OVERWRITEABLE = [:originators, :answerers, :doctype]

  def perform(paper)
    return unless paper.body.scraper.const_defined? :Detail

    logger.info "Loading details for Paper [#{paper.body.state} #{paper.full_reference}]"
    scraper = paper.body.scraper::Detail.new(paper.legislative_term, paper.reference)
    scraper.logger = logger

    results = scraper.scrape

    if results.nil?
      logger.warn 'Detail Scraper for Paper [#{paper.body.state} #{paper.full_reference}] got nothing'
      return
    end

    results.each do |key, value|
      paper.send("#{key}=", value) if paper.send(key).blank? || OVERWRITEABLE.include?(key)
    end

    paper.save
  end
end