class FetchPapersBerlinJob < FetchPapersJob

  @state = 'BE'

  def perform(*params)
    super

    import_new_papers
    download_papers
    extract_text_from_papers
    count_page_numbers
  end

  def import_new_papers
    result = BerlinAghScraper::Overview.new.scrape
    result.each do |item|
      item[:reference] = item[:full_reference].split("/").last
      originators = item[:originators]
      item.delete :full_reference
      item.delete :originators
      unless Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
        Rails.logger.info "Got new Paper: [#{item[:reference]}] \"#{item[:title]}\""
        paper = Paper.new(item)
        paper.body = @body
        paper.save

        originators.split(',').each do |originator|
          name_and_party = originator.strip.match(/([^\(]+) \(([^\)]+)\)/)
          name = name_and_party[1]
          party = name_and_party[2]

          # party
          org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
          Rails.logger.info "- Originator: #{org.name}"
          unless paper.originator_organizations.include? org
            paper.originator_organizations << org
            paper.save
          end

          # person
          person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
          Rails.logger.info "- Originator: #{person.name}"
          unless paper.originator_people.include? person
            paper.originator_people << person
            paper.save
          end
        end
      end
    end
  end
end