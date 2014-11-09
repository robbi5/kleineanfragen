class FetchPapersBayernJob < FetchPapersJob

  @state = 'BY'

  def self.perform(*params)
    super

    import_new_papers
    load_paper_details
    download_papers
    extract_text_from_papers
    count_page_numbers
    extract_people_names
  end

  def self.import_new_papers
    (1...5).each do |page|
      found_new_paper = false
      result = BayernLandtagScraper::Overview.new.scrape(page)
      result.each do |item|
        item.delete :full_reference
        unless Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
          puts "Got new Paper: [#{item[:reference]}] \"#{item[:title]}\""
          paper = Paper.new(item)
          paper.body = @body
          paper.save
          found_new_paper = true
        end
      end
      if !found_new_paper
        break
      end
    end
  end

  def self.load_paper_details
    @papers = Paper.find_by_sql(
      ["SELECT p.* FROM papers p LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id) WHERE p.body_id = ? AND o.id IS NULL", @body.id])

    @papers.each do |paper|
      puts "Loading details for Paper [#{paper.reference}]"
      detail = BayernLandtagScraper::Detail.new(paper.legislative_term, paper.reference).scrape
      org = Organization.where('lower(name) = ?', detail[:originator].mb_chars.downcase.to_s).first_or_create(name: detail[:originator])
      puts "- Originator: #{org.name}"
      unless paper.originator_organizations.include? org
        paper.originator_organizations << org
        paper.save
      end
    end
  end

  # FIXME: cleanup
  def self.extract_people_names
    @papers = Paper.find_by_sql(
      ["SELECT p.* FROM papers p LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id AND o.originator_type = 'Person') WHERE p.body_id = ? AND o.id IS NULL", @body.id])

    @papers.each do |paper|
      originators = BayernPDFExtractor.new(paper).extract
      next if originators.nil?

      if !originators[:party].empty?
        # write org
        party = originators[:party]
        org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
        unless paper.originator_organizations.include? org
          paper.originator_organizations << org
          paper.save
        end
      end

      if !originators[:people].empty?
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
end