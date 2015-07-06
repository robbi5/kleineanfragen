class ImportNewPapersJob < ActiveJob::Base
  queue_as :import

  def self.perform_async(body, legislative_term)
    result = body.scraper_results.create
    params = [body, legislative_term, result]
    send(:perform_later, *params)
    result.to_param
  end

  # NOTE: after_perform must be before around_perform, else @result won't be filled
  after_perform do
    SendBodySubscriptionsJob.perform_later(@body) if @result.success?
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
    @result.save
    fail failure unless failure.nil?
  end

  def perform(body, legislative_term)
    fail "No scraper found for body #{body.state}" if body.scraper.nil?
    @body = body
    @legislative_term = legislative_term
    @scraper = @body.scraper::Overview.new(legislative_term)
    @scraper.logger = logger
    @load_details = @body.scraper.const_defined?(:Detail)
    @new_papers = 0
    @old_papers = 0
    if @scraper.supports_pagination?
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
        if Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference], is_answer: true).exists?
          @old_papers += 1
          next
        end
        on_item(item)
        found_new_paper = true
      end
      page += 1
      break unless found_new_paper
    end
  end

  def scrape_single_page
    logger.info "Importing #{@body.state} - Single Page"
    block = lambda do |item|
      if Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference], is_answer: true).exists?
        @old_papers += 1
        return
      end
      on_item(item)
    end
    if @scraper.supports_streaming?
      @scraper.scrape(&block)
    else
      @scraper.scrape.each(&block)
    end
  end

  def on_item(item)
    new_paper = false
    if Paper.unscoped.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
      paper = Paper.unscoped.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).first
      if paper.frozen?
        logger.info "[#{@body.state}] Skipping Paper [#{item[:full_reference]}] - frozen"
        return
      end

      logger.info "[#{@body.state}] Updating Paper: [#{item[:full_reference]}] \"#{item[:title]}\""

      if !paper.is_answer && item[:is_answer] == true
        # changed state, answer is now available. reset created_at, so subscriptions get triggered
        paper.created_at = DateTime.now
        @new_papers += 1
        new_paper = true
      else
        @old_papers += 1
      end

      if !paper.is_answer && item[:is_answer].nil?
        # don't know if we have the answer this time, so we have to run the full pipeline
        new_paper = true
      end

      paper.assign_attributes(item.except(:full_reference, :body, :legislative_term, :reference))
      paper.save!
    else
      logger.info "[#{@body.state}] New Paper: [#{item[:full_reference]}] \"#{item[:title]}\""
      paper = Paper.create!(item.except(:full_reference).merge(body: @body))
      @new_papers += 1
      new_paper = true
    end
    LoadPaperDetailsJob.perform_later(paper) if item_missing_fields?(item) && @load_details
    StorePaperPDFJob.perform_later(paper, force: new_paper) unless paper.url.blank?
  end

  def item_missing_fields?(item)
    item[:originators].blank? ||
      item[:answerers].blank? ||
      item[:published_at].blank? ||
      item[:title].blank? ||
      item[:url].blank?
  end
end