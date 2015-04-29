module SchleswigHolsteinLandtagScraper
  BASE_URL = 'http://lissh.lvn.parlanet.de'

  def self.extract_table(page)
    page.search('//center')[0].next.next.next
  end

  def self.extract_blocks(table)
    table.search('//tr[contains(@class, "tabcol")][not(@class="tabcol2")]')
  end

  def self.extract_title(block)
    block.child.next.child.next.content
  end

  def self.answer?(block)
    block.content.scan(/in Vorbereitung/)[0].nil? && !block.content.scan(/Kleine Anfrage.+und Antwort/)[0].nil?
  end

  def self.extract_meta(block)
    line = block.child.next.child.next.next.next.content
    line = line.sub(/Kleine Anfrage/, '').sub(/Drucksache/, '')
    matches = /\d{2}\.\d{2}\.\d{4}/.match(line)
    return nil if matches.nil?
    published_at = Date.parse(matches[0])
    line = line.sub(matches[0], '').strip
    parts = line.split('und Antwort')
    originators_with_party = parts[0]
    ministry = parts[1].strip
    originators = NamePartyExtractor.new(originators_with_party).extract
    {
      ministries: [ministry],
      originators: originators,
      published_at: published_at
    }
  end

  def self.extract_paper(block)
    return nil if !answer?(block)
    full_reference = extract_full_reference(block)
    meta = extract_meta(block)
    fail "SH [#{full_reference}]: missing meta data" if meta.nil?
    url = extract_url(block)
    legislative_term, reference = full_reference.split('/')
    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      published_at: meta[:published_at],
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      title: SchleswigHolsteinLandtagScraper.extract_title(block),
      url: url,
      originators: meta[:originators],
      is_answer: true,
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
        rescue => e
          logger.warn e
          next
        end
        next if paper.nil?
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
      search_url = SEARCH_URL + '(' + CGI.escape('WP=' + @legislative_term.to_s + ' AND DART=D AND DNR=' + @reference.to_s) + ')'
      mp = mechanize.get search_url
      table = SchleswigHolsteinLandtagScraper.extract_table(mp)
      block = SchleswigHolsteinLandtagScraper.extract_blocks(table).first
      SchleswigHolsteinLandtagScraper.extract_paper(block)
    end
  end
end