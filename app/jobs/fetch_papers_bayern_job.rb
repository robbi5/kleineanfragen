class FetchPapersBayernJob

  def self.perform(*params)
    @bayern = Body.find_by(state: 'BY')
    raise 'Required body "Bayern" not found' if @bayern.nil?
    @papers = []

    import_new_papers
    load_paper_details
  end

  def self.import_new_papers
    result = BayernLandtagScraper::Overview.new.scrape
    result.each do |item|
      item['reference'] = item['full_reference'].split("/").last
      item.delete 'full_reference'
      unless Paper.where(body: @bayern, legislative_term: item['legislative_term'], reference: item['reference']).exists?
        puts "Got new Paper: [#{item['reference']}] \"#{item['title']}\""
        paper = Paper.new(item)
        paper.body = @bayern
        paper.save
        @papers << paper
      end
    end
  end

  def self.load_paper_details
    @papers.each do |paper|
      puts "Loading details for Paper [#{paper.reference}]"
      org = Organization.find_or_create_by(name: detail[:originator])
      detail = BayernLandtagScraper::Detail.new(paper.legislative_term, paper.reference).scrape
      puts "- Originator: #{org.name}"
      unless paper.originator_organizations.include? org
        paper.originator_organizations << org
        paper.save
      end
    end
  end

end