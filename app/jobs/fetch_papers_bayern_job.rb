class FetchPapersBayernJob < FetchPapersJob

  @state = 'BY'

  def self.perform(*params)
    super

    import_new_papers
    load_paper_details
    download_papers
  end

  def self.import_new_papers
    result = BayernLandtagScraper::Overview.new.scrape
    result.each do |item|
      item['reference'] = item['full_reference'].split("/").last
      item.delete 'full_reference'
      unless Paper.where(body: @body, legislative_term: item['legislative_term'], reference: item['reference']).exists?
        puts "Got new Paper: [#{item['reference']}] \"#{item['title']}\""
        paper = Paper.new(item)
        paper.body = @body
        paper.save
      end
    end
  end

  def self.load_paper_details
    @papers = Paper.find_by_sql(
      ["SELECT p.* FROM papers p LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id) WHERE p.body_id = ? AND o.id IS NULL LIMIT 25", @body.id])

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

end