class ImportNewPapersJob < ActiveJob::Base
  queue_as :import

  def perform(body, legislative_term)
    fail "No scraper found for body #{body.state}" if body.scraper.nil?
    @body = body
    @legislative_term = legislative_term
    @scraper = @body.scraper::Overview.new(legislative_term)
    @load_details = @body.scraper.const_defined?(:Detail)
    if @scraper.supports_pagination?
      scrape_paginated
    else
      scrape_single_page
    end
    Rails.logger.info "Importing #{@body.state} done."
  end

  def scrape_paginated
    page = 1
    found_new_paper = false
    loop do
      Rails.logger.info "Importing #{@body.state} - Page #{page}"
      found_new_paper = false
      @scraper.scrape(page).each do |item|
        next if Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
        on_item(item)
        found_new_paper = true
      end
      page += 1
      break unless found_new_paper
    end
  end

  def scrape_single_page
    Rails.logger.info "Importing #{@body.state} - Single Page"
    @scraper.scrape.each do |item|
      next if Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
      on_item(item)
    end
  end

  def on_item(item)
    Rails.logger.info "New Paper: [#{item[:reference]}] \"#{item[:title]}\""
    paper = Paper.create!(item.except(:full_reference).except(:originators).merge({ body: @body }))
    if item[:originators].blank?
      LoadPaperDetailsJob.perform_later(paper) if @load_details
    else
      originators = item[:originators]
      unless originators[:parties].blank?
        # write parties
        originators[:parties].each do |party|
          Rails.logger.debug "+ Originator: #{party}"
          org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
          unless paper.originator_organizations.include? org
            paper.originator_organizations << org
            paper.save
          end
        end
      end

      unless originators[:people].blank?
        # write people
        originators[:people].each do |name|
          Rails.logger.debug "+ Originator: #{name}"
          person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
          unless paper.originator_people.include? person
            paper.originator_people << person
            paper.save
          end
        end
      end
    end
    StorePaperPDFJob.perform_later(paper)
  end
end