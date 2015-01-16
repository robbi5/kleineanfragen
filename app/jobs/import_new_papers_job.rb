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

  # TODO: rewrite
  def on_item(item)
    Rails.logger.info "New Paper: [#{item[:reference]}] \"#{item[:title]}\""
    paper = Paper.create!(item.except(:full_reference, :originators, :answerers).merge({ body: @body }))
    should_trigger_load_paper_details = false
    if item[:originators].blank?
      should_trigger_load_paper_details = true
    else
      originators = item[:originators]
      unless originators[:parties].blank?
        # write parties
        originators[:parties].each do |party|
          party = normalize(party, 'parties')
          Rails.logger.debug "+ Originator (Party): #{party}"
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
          name = normalize(name, 'people', paper.body)
          Rails.logger.debug "+ Originator (Person): #{name}"
          person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
          unless paper.originator_people.include? person
            paper.originator_people << person
            paper.save
          end
        end
      end
    end
    if item[:answerers].blank?
      should_trigger_load_paper_details = true
    else
      answerers = item[:answerers]
      unless answerers[:ministries].blank?
        # write ministries
        answerers[:ministries].each do |ministry|
          unless ministry.is_a? Ministry
            ministry = normalize(ministry, 'ministries', paper.body)
            ministry = Ministry
                       .where(body: paper.body)
                       .where('lower(name) = ?', ministry.mb_chars.downcase.to_s)
                       .first_or_create(body: paper.body, name: ministry)
          end
          Rails.logger.debug "+ Ministry: #{ministry.name}"
          unless paper.answerer_ministries.include? ministry
            paper.answerer_ministries << ministry
            paper.save
          end
        end
      end
    end
    LoadPaperDetailsJob.perform_later(paper) if should_trigger_load_paper_details && @load_details
    StorePaperPDFJob.perform_later(paper)
  end

  def normalize(name, prefix, body = nil)
    return name if Rails.configuration.x.nomenklatura_api_key.blank?
    Nomenklatura::Dataset.new("ka-#{prefix}" + (!body.nil? ? "-#{body.state}" : '')).lookup(name)
  end
end