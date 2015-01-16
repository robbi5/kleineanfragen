class ExtractOriginatorsJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    # FIXME: generic?
    return unless paper.body.state == 'BY'
    Rails.logger.info "Extracting Originators from Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    originators = BayernPDFExtractor.new(paper).extract_originators
    if originators.nil?
      Rails.logger.warn "No Names found in Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    unless originators[:parties].blank?
      # write org
      originators[:parties].each do |party|
        party = normalize(party, 'parties')
        Rails.logger.debug "+ Originator: #{party}"
        org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
        unless paper.originator_organizations.include? org
          paper.originator_organizations << org
          paper.save
        end
      end
    else
      Rails.logger.warn "No Parties found in Paper [#{paper.body.state} #{paper.full_reference}]"
    end

    unless originators[:people].blank?
      # write people
      originators[:people].each do |name|
        name = normalize(name, 'people', paper.body)
        Rails.logger.debug "+ Originator: #{name}"
        person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
        unless paper.originator_people.include? person
          paper.originator_people << person
          paper.save
        end
      end
    else
      Rails.logger.warn "No People found in Paper [#{paper.body.state} #{paper.full_reference}]"
    end
  end

  def normalize(name, prefix, body = nil)
    return name if Rails.configuration.x.nomenklatura_api_key.blank?
    Nomenklatura::Dataset.new("ka-#{prefix}" + (!body.nil? ? "-#{body.state}" : '')).lookup(name)
  end
end