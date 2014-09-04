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
      detail = BayernLandtagScraper::Detail.new(paper.reference).scrape
      org = Organization.find_or_create_by(name: detail[:originator])
      puts "- Originator: #{org.name}"
      unless paper.originator_organizations.include? org
        paper.originator_organizations << org
        paper.save
      end
    end
  end

end