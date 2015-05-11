module NordrheinWestfalenLandtagScraper
  BASE_URL = 'http://www.landtag.nrw.de/portal/WWW'

  def self.extract_blocks(mp)
    table = mp.search("//div[@id='content']//table").first
    table.search('.//tr/td[3]')
  end

  def self.extract_meta(text)
    meta = text.match(/Antwort\s+(.+)\s+zu\s+(.+)\s+\d+(\s+.+)?\s+Drs/)

    doctype = case meta[2].downcase
              when 'klanfr' then Paper::DOCTYPE_MINOR_INTERPELLATION
              when 'granfr' then Paper::DOCTYPE_MAJOR_INTERPELLATION
              end

    originators = nil
    originators = { people: [], parties: [meta[3].strip] } if doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION

    {
      answerer: meta[1],
      doctype: doctype,
      originators: originators
    }
  end

  def self.extract_paper(block, resolve_pdf: true)
    title = block.search(".//p[contains(@id, 'titel')]").first.text.strip
    link = block.at_css('a')
    full_reference = link.text.match(/Drucksache\s+([\d\/]+)/)[1]
    legislative_term, reference = full_reference.split('/')

    meta_text = link.previous.text.strip
    meta = extract_meta(meta_text)
    fail "unknown doctype for paper [NW #{full_reference}]" if meta[:doctype].nil?

    date_text = link.next.text.strip
    date = date_text.match(/([\d\.]+)/)[1]

    url = link.attributes['href'].value
    url = Addressable::URI.parse(BASE_URL).join(url).normalize.to_s

    if resolve_pdf
      # NW Server doesn't support head, so use a GET request with no redirects
      patron = Scraper.patron_session
      patron.max_redirects = 0
      begin
        resp = patron.get(url)
      rescue => e
        raise "NW [#{full_reference}]: url throwed #{e}"
      end
      url = resp.headers.try(:[], 'Location') || resp.url
    end

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: meta[:doctype],
      title: title,
      url: url,
      published_at: Date.parse(date),
      # more originators are handled in detail scraper
      originators: meta[:originators],
      is_answer: true,
      answerers: { ministries: [meta[:answerer]] }
    }
  end

  def self.extract_paper_details(block)
    link = block.at_css('a')
    originators_text = link.previous.text.strip
    originators = NamePartyExtractor.new(originators_text, NamePartyExtractor::REVERSED_NAME_PARTY).extract

    {
      originators: originators
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/Webmaster/GB_II/II.2/Suche/Landtagsdokumentation_ALWP/Suchergebnisse_Ladok.jsp?' +
                 'w=native%28%27%28DOKUMENTART+phrase+like+%27%27DRUCKSACHE%27%27%29+and+%28DOKUMENTTYP+phrase+like+%27%27ANTWORT%27%27%29%27%29' +
                 '&fm=&order=native%28%27DOKDATUM%281%29%2FDescend+%2C+VA%281%29%2FDescend+%27%29&maxRows=100&view=kurz'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      mp = m.get SEARCH_URL + "&wp=#{@legislative_term}"

      # Fail if no hits
      fail 'search returns no results' if mp.search('//div[@id="content"]').first.text.include?('Mit Ihren Suchkriterien wurde leider nichts gefunden')

      papers = []

      loop do
        NordrheinWestfalenLandtagScraper.extract_blocks(mp).each do |item|
          begin
            paper = NordrheinWestfalenLandtagScraper.extract_paper(item)
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

        # Pagination
        next_link = mp.search('//div[@class="paging_center"]//a[@accesskey="2"]').try(:first)
        break if next_link.nil?
        mp = m.click next_link
      end

      papers unless streaming
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/Webmaster/GB_II/II.2/Suche/Landtagsdokumentation_ALWP/Suchergebnisse_Ladok.jsp?' +
                 'order=native%28%27DOKDATUM%281%29%2FDescend+%2C+VA%281%29%2FDescend+%27%29&fm='

    def scrape
      url = SEARCH_URL + "&wp=#{@legislative_term}&w=" +
            CGI.escape("native('(NUMMER phrase like ''#{@reference}'') " +
            "and (DOKUMENTART phrase like ''DRUCKSACHE'') and (DOKUMENTTYP phrase like ''ANTWORT'')')")
      m = mechanize
      mp = m.get url

      blocks = NordrheinWestfalenLandtagScraper.extract_blocks(mp)
      item = nil
      blocks.each do |block|
        # matching number is highlighted with strong
        if block.search(".//a/strong[contains(text(), '#{@reference}')]/..").present?
          item = block
          break
        end
      end
      fail "NW [#{full_reference}]: cannot find relevant block" if item.nil?

      paper = NordrheinWestfalenLandtagScraper.extract_paper(item)

      mp = m.click item.search(".//a[contains(text(), 'Beratungsverlauf')]").first

      detail_item = NordrheinWestfalenLandtagScraper.extract_blocks(mp)
      paper.merge NordrheinWestfalenLandtagScraper.extract_paper_details(detail_item)
    end
  end
end
