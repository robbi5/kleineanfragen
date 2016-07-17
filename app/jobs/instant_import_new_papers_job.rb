class InstantImportNewPapersJob < ApplicationJob
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

    @importer = PaperImporter.new(@body)
    logger.progname = "InstantImportNewPapersJob #{@body.state}"
    @importer.logger = logger

    @new_papers = @old_papers = 0

    fail "No instant scraper found for body #{body.state}" if !body.scraper.const_defined?(:Instant)
    @scraper = @body.scraper::Instant.new(legislative_term)

    @scraper.scrape { |item| import(item) }
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