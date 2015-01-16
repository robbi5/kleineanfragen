class LoadPaperDetailsJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    return unless paper.body.scraper.const_defined? :Detail

    Rails.logger.info "Loading details for Paper [#{paper.body.state} #{paper.full_reference}]"
    detail = paper.body.scraper::Detail.new(paper.legislative_term, paper.reference).scrape
    originators = detail[:originators]

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

  def normalize(name, prefix, body = nil)
    return name if Rails.configuration.x.nomenklatura_api_key.blank?
    Nomenklatura::Dataset.new("ka-#{prefix}" + (!body.nil? ? "-#{body.state.downcase}" : '')).lookup(name)
  end
end