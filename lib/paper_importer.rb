class PaperImporter
  attr_accessor :logger

  def initialize(body)
    @body = body
    @load_details = @body.scraper.const_defined?(:Detail)
    @logger ||= Rails.logger
  end

  def import(item)
    new_paper = false

    # we know that answered paper already? skip.
    # FIXME: maybe it should be diffed / update empty fields...
    if Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference], is_answer: true).exists?
      return false
    end

    # we know that unanswered paper already?
    if Paper.unscoped.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
      paper = Paper.unscoped.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).first
      if paper.frozen?
        logger.info "[#{@body.state}] Skipping Paper [#{item[:full_reference]}] - frozen"
        return false
      end

      if paper.deleted?
        logger.info "[#{@body.state}] Skipping Paper [#{item[:full_reference]}] - deleted"
        return false
      end

      logger.info "[#{@body.state}] Updating Paper: [#{item[:full_reference]}] \"#{item[:title]}\""

      if !paper.is_answer && item[:is_answer] == true
        # changed state, answer is now available. reset created_at, so subscriptions get triggered
        paper.created_at = DateTime.now
        new_paper = true
      end

      if !paper.is_answer && item[:is_answer].nil?
        # don't know if we have the answer this time, so we have to run the full pipeline
        new_paper = true
      end

      paper.assign_attributes(item.except(:full_reference, :body, :legislative_term, :reference))
      if !paper.valid?
        logger.warn "[#{@body.state}] Can't save Paper [#{item[:full_reference]}] - #{paper.errors.messages}"
        return false
      end
      paper.save!
    else
      logger.info "[#{@body.state}] New Paper: [#{item[:full_reference]}] \"#{item[:title]}\""
      paper = Paper.new(item.except(:full_reference).merge(body: @body))
      if !paper.valid?
        logger.warn "[#{@body.state}] Can't save Paper [#{item[:full_reference]}] - #{paper.errors.messages}"
        return false
      end
      paper.save!
      new_paper = true
    end
    LoadPaperDetailsJob.perform_later(paper) if item_missing_fields?(item) && @load_details
    StorePaperPDFJob.perform_later(paper, force: new_paper) unless paper.url.blank?
    new_paper
  end

  private

  def item_missing_fields?(item)
    item[:originators].blank? ||
      item[:answerers].blank? ||
      item[:published_at].blank? ||
      item[:title].blank? ||
      item[:url].blank?
  end
end