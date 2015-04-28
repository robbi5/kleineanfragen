module SchleswigHolsteinLandtagScraper
  BASE_URL = 'http://lissh.lvn.parlanet.de'

  def self.extract_table(page)
    page.search('//center')[0].next.next.next
  end

  def self.extract_blocks(table)
    evenrows = table.search('//tr[@class="tabcol"]').to_a
    oddrows = table.search('//tr[@class="tabcol3"]').to_a
    evenrows.concat(oddrows)
  end

  def self.extract_title(block)
    block.child.next.child.next.content
  end

  def self.is_answer(block)
    block.content.scan(/in Vorbereitung/)[0].nil? && !block.content.scan(/Kleine Anfrage.+und Antwort/)[0].nil?
  end

 def self.extract_meta(block)
   ministries = []
   answered = is_answer(block)
   line = block.child.next.child.next.next.next.content
   line = line.sub(/Kleine Anfrage/, '').sub(/Drucksache/, '')
   matches=/\d{2}\.\d{2}\.\d{4}/.match(line)
   published_date = Date.parse(matches[0]) unless matches.nil?
   line.sub(/\d{2}\.\d{2}\.\d{4}/, '')
   parts = line.split('und Antwort')
   originators_with_party = parts[0]
   originators_with_party = parts[1] unless answered
   ministry = parts[1] if answered
   ministries.push(ministry.strip!) if answered
   originators = NamePartyExtractor.new(originators_with_party).extract
   {
     ministries: ministries,
     originators: originators,
     published_date: published_date
   }
 end

  def self.extract_paper(block)
    full_reference = SchleswigHolsteinLandtagScraper.extract_full_reference(block)
    meta = SchleswigHolsteinLandtagScraper.extract_meta(block)
    answered = SchleswigHolsteinLandtagScraper.is_answer(block)
    url = SchleswigHolsteinLandtagScraper.extract_url(block) if answered
    legislative_term, reference = full_reference.split('/')
    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      published_date: meta[:published_date],
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      title: SchleswigHolsteinLandtagScraper.extract_title(block),
      url: url,
      originators: meta[:originators],
      is_answer: answered,
      answerers: { ministries: meta[:ministries] }
    }
  end

  def self.extract_full_reference(block)
    block.child.next.child.next.next.next.next.content
  end

  def self.extract_url(block)
    block.child.next.child.next.next.next.next.attributes['href'].value
  end

  class Overview < Scraper

    SEARCH_URL = BASE_URL + '/cgi-bin/starfinder/0?path=lisshfl.txt&id=fastlink&pass=&search='
    #'((dtyp%3dkleine+and+WP%3d$1))'
    def supports_streaming?
      true
    end

    def scrape
      search_url = SEARCH_URL + CGI.escape('WP=' + @legislative_term.to_s + ' AND dtyp=kleine')
      streaming = block_given?
      m = mechanize
      mp = m.get search_url

      table = SchleswigHolsteinLandtagScraper.extract_table(mp)
      papers = []
      SchleswigHolsteinLandtagScraper.extract_blocks(table).each do |block|
        begin
          paper = SchleswigHolsteinLandtagScraper.extract_paper(block)
          puts paper
        rescue => e
          logger.warn e
          next
        end
        if streaming
          yield paper
        else
          papers << paper
        end
      end
      papers unless streaming
    end
  end

  class Detail < DetailScraper

    SEARCH_URL = BASE_URL + '/cgi-bin/starfinder/0?path=lisshfl.txt&id=FASTLINK&pass=&search='

    def scrape
      search_url = SEARCH_URL + '(' + CGI.escape('WP=' + @legislative_term.to_s + ' AND dtyp=kleine' + ' AND DNR=' + @reference.to_s) + ')'
      mp = mechanize.get search_url
      table = SchleswigHolsteinLandtagScraper.extract_table(mp)
      block = SchleswigHolsteinLandtagScraper.extract_blocks(table).first
      SchleswigHolsteinLandtagScraper.extract_paper(block)
    end
  end

end
