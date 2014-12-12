class ExtractPeopleNamesJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    # FIXME: generic?
    return unless paper.body.state == 'BY'
    Rails.logger.info "Extracting Names of People from Paper [#{paper.body.state} #{paper.full_reference}]"

    originators = BayernPDFExtractor.new(paper).extract
    return if originators.nil?

    unless originators[:party].blank?
      # write org
      party = originators[:party]
      org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
      unless paper.originator_organizations.include? org
        paper.originator_organizations << org
        paper.save
      end
    end

    unless originators[:people].blank?
      # write people
      originators[:people].each do |name|
        person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
        unless paper.originator_people.include? person
          paper.originator_people << person
          paper.save
        end
      end
    end
  end
end