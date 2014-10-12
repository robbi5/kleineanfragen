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
      if m = paper.contents.match(/de[rs](?:\/des)?\s?Abgeordneten (\D+?)\s(\p{Lu}[\p{Lu} \d\/]+)\b/m)
        person = m[1]
        person = person.gsub("\n", '').gsub(' und', ', ')
        if person.include?(',')
          people = person.split(',').map { |n| n.strip }
        else
          people = [person]
        end
        party = m[2]

        #puts [paper.id, people, party].inspect

        # write org
        org = Organization.where('lower(name) = ?', party.mb_chars.downcase.to_s).first_or_create(name: party)
        unless paper.originator_organizations.include? org
          paper.originator_organizations << org
          paper.save
        end

        # write people
        people.each do |name|
          person = Person.where('lower(name) = ?', name.mb_chars.downcase.to_s).first_or_create(name: name)
          unless paper.originator_people.include? person
            paper.originator_people << person
            paper.save
          end
        end
      else
        #puts "- #{paper.id}"
      end
    end
  end
end