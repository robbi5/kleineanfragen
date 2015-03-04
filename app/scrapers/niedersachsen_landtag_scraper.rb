module NiedersachsenLandtagScraper
  BASE_URL = 'http://www.nilas.niedersachsen.de'

  def self.extract_blocks(page)
    page.search('/html/body/form/div/table[@id="listTable"]/tr/td/table[@id="listTable"]').map(&:previous_element)
  end

  def self.extract_references_block(block)
    block.try(:next_element)
  end

  def self.extract_detail_block(page)
    page.search('//table[@summary="Report"]//table')
  end

  def self.extract_title(block)
    block.css('tr:nth-child(2) td:nth-child(2)').first.try(:text)
  end

  def self.extract_is_answer(container)
    container.css('b').last.try(:text).scan(/Beantwortung\s+mit\s+Antwort/m).size>=1
  end

  def self.extract_container(block)
    block.css('tr:nth-child(4) td:nth-child(2) table tr td:nth-child(2)').first
  end

  def self.extract_link(container)
    container.css('a').select { |el| el.text.include? '/' }.last
  end

  def self.extract_full_reference(link)
    link.text.strip
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_url(link)
    link.attributes['href'].value
  end

  def self.extract_meta(container)
    o_results, a_results = [nil, nil]
    container.children.map(&:text).each do |line|
      match = line.match(/Kleine\s+Anfrage(?:\s+zur\s+schriftlichen\s+Beantwortung)?\s+(.+\))/m)
      o_results = match if match
      match = line.match(/Antwort\s+(.+)\s+([\d\.]+)/m)
      a_results = match if match
    end
    fail 'cannot extract metadata' if o_results.nil? || a_results.nil?
    {
      originators: o_results[1].strip,
      answerers: a_results[1].strip,
      published_at: a_results[2]
    }
  end

  def self.extract_paper(item)
    fail 'NS [?]: called extract_paper with null parameter' if item.nil?
    details = extract_references_block(item)
    title = extract_title(details)
    fail 'NS [?]: no title element found' if title.nil?

    references = extract_container(details)
    link = extract_link(references)
    fail "NS [?]: no link element found. Paper title: #{title}" if link.nil?

    full_reference = extract_full_reference(link)
    is_answer = extract_is_answer(item)
    legislative_term, reference = extract_reference(full_reference)
    url = extract_url(link)
    meta = extract_meta(references)
    fail "NS [#{full_reference}]: no readable meta information found" if meta.nil?

    ministries = []
    originators = NamePartyExtractor.new(meta[:originators]).extract
    ministries = [meta[:answerers]] unless meta[:answerers].nil?
    published_at = Date.parse(meta[:published_at])

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      title: title,
      url: url,
      published_at: published_at,
      originators: originators,
      is_answer: is_answer,
      answerers: { ministries: ministries }
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/NILAS/servlet.starweb?path=NILAS/lissh.web'
    TYPE = 'Kleine Anfrage Zur Schriftlichen Beantwortung Mit Antwort'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      mp = m.get SEARCH_URL
      search_form = mp.form '__form'
      # fill search form
      search_form.field_with(name: '__action').value = 4
      search_form.field_with(name: 'wplist').value = @legislative_term
      search_form.field_with(name: 'Suchzeile6').value = TYPE
      mp = m.submit(search_form)

      # retrieve new search form with more options
      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 5
      search_form.add_field!('ReportFormatListDisplay', 'Vollanzeige')

      # Fail if no hits
      fail 'search returns no results' if mp.search('//span[@name="DBSearched"]').first.text.to_i == 0

      mp = m.submit(search_form)

      papers = []

      NiedersachsenLandtagScraper.extract_blocks(mp).each do |item|
        begin
          paper = NiedersachsenLandtagScraper.extract_paper(item)
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
    SEARCH_URL = BASE_URL + '/starweb/NILAS/servlet.starweb?path=NILAS/lisshfl.web&id=NILASWEBDOKFL&format=WEBDOKFL&search='

    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape("(DART=D AND WP=#{@legislative_term} AND DNR,KORD=#{@reference})")
      item = NiedersachsenLandtagScraper.extract_detail_block(mp)
      NiedersachsenLandtagScraper.extract_paper(item)
    end
  end
end
