class FetchPapersBrandenburgJob < FetchPapersJob

  @state = 'BB'

  def perform(*params)
    super

    import_new_papers
    download_papers
    extract_text_from_papers
    count_page_numbers
  end

  def import_new_papers
    result = BrandenburgLandtagScraper::Overview.new.scrape
    result.each do |item|
      item[:reference] = item[:full_reference].split("/").last
      originators = item[:originators]
      item.delete :full_reference
      item.delete :originators
      unless Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
        puts "Got new Paper: [#{item[:reference]}] \"#{item[:title]}\""
        paper = Paper.new(item)
        paper.body = @body
        paper.save

        # party
        unless originators[:party].nil?
          party = originators[:party]
          org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
          puts "- [O] Party: #{org.name}"
          unless paper.originator_organizations.include? org
            paper.originator_organizations << org
            paper.save
          end
        end

        originators[:people].split(',').each do |name|
          # person
          person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
          puts "- [O] Person: #{person.name}"
          unless paper.originator_people.include? person
            paper.originator_people << person
            paper.save
          end
        end
      end
    end
  end
end