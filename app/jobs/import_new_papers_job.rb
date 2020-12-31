class ImportNewPapersJob < ApplicationJob
  queue_as :import

  def self.perform_async(body, legislative_term)
    result = body.scraper_results.create
    params = [body, legislative_term, result]
    send(:perform_later, *params)
    result.to_param
  end

  # NOTE: after_perform must be before around_perform, else @result won't be filled
  after_perform do
    NotifyPuSHHubBodyFeedJob.perform_later(@body) if @result.success?
  end

  around_perform do |job, block|
    body = job.arguments.first
    if job.arguments.last.is_a? ScraperResult
      @result = job.arguments.pop
      @result.started_at = DateTime.now
      @result.save
    else
      @result = body.scraper_results.create(started_at: DateTime.now)
    end
    failure = nil
    begin
      block.call
    rescue => e
      failure = e
    end
    @result.stopped_at = DateTime.now
    @result.success = failure.nil?
    @result.message = failure.nil? ? nil : failure.message
    if !@new_papers.nil? && !@old_papers.nil?
      @result.new_papers = @new_papers
      @result.old_papers = @old_papers
    end
    @result.scraper_class = @scraper.class.name if !@scraper.nil?
    @result.save
    fail failure unless failure.nil?
  end

  def perform(body, legislative_term)
    fail "No scraper found for body #{body.state}" if body.scraper.nil?
    @body = body
    @legislative_term = legislative_term
    @scraper = @body.scraper::Overview.new(legislative_term)
    @importer = PaperImporter.new(@body)
    logger.progname = "ImportNewPapersJob #{@body.state}"
    @scraper.logger = @importer.logger = logger
    @new_papers = 0
    @old_papers = 0
    if @scraper.supports_typed_pagination?
      scrape_paginated_type
    elsif @scraper.supports_pagination?
      scrape_paginated
    else
      scrape_single_page
    end
    logger.info "Importing #{@body.state} #{@legislative_term} done. #{@new_papers} new Papers, #{@old_papers} old Papers."
  end

  def scrape_paginated
    page = 1
    found_new_paper = false
    loop do
      logger.info "Importing #{@body.state} - Page #{page}"
      found_new_paper = false
      @scraper.scrape_paginated(page) do |item|
        found_new_paper ||= import(item)
      end
      page += 1
      break unless found_new_paper
    end
  end

  def scrape_paginated_type
    [Paper::DOCTYPE_MINOR_INTERPELLATION, Paper::DOCTYPE_MAJOR_INTERPELLATION].each do |type|
      page = 1
      found_new_paper = false
      loop do
        logger.info "Importing #{@body.state}, Type: #{type} - Page #{page}"
        found_new_paper = false
        found_papers = 0
        has_next_page = @scraper.scrape_paginated_type(type, page) do |item|
          found_papers += 1
          found_new_paper ||= import(item)
        end
        page += 1
        break if !has_next_page || (!found_new_paper && found_papers > 0)
      end
    end
  end

  def scrape_single_page
    logger.info "Importing #{@body.state} - Single Page"
    block = lambda do |item|
      import(item)
    end
    if @scraper.supports_streaming?
      @scraper.scrape(&block)
    else
      @scraper.scrape.each(&block)
    end
  end

  def import(item)
    is_new_paper = @importer.import(item)
    if is_new_paper
      @new_papers += 1
    else
      @old_papers += 1
    end
    is_new_paper
  end
end