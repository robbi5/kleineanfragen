module NiedersachsenLandtagScraper
  BASE_URL = 'http://www.nilas.niedersachsen.de'

  def self.extract_blocks(page)
    page.search('//table[@id="listTable"]//table[@id="listTable"]').map(&:previous_element)
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
    container.css('b').last.try(:text).scan(/mit\s+Antwort/m).size >= 1
  end

  def self.extract_container(block)
    block.css('tr:nth-child(4) td:nth-child(2) table tr td:nth-child(2)').first
  end

  def self.extract_link(container)
    links = container.css('a')
    return nil if links.nil? || links.size == 0
    links.select { |el| el.text.include?('/') && !el.previous.text.include?('Plenarprotokoll') }.last
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

  def self.extract_doctype(doctype)
    case doctype.downcase
    when 'kleine'
      Paper::DOCTYPE_MINOR_INTERPELLATION
    when 'große'
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
  end

  def self.extract_meta(container)
    o_results, a_results = [nil, nil]
    container.children.map(&:text).each do |line|
      match = line.match(/(Kleine|Große)\s+Anfrage(?:\s+zur\s+schriftlichen\s+Beantwortung)?\s+(.+)(?:\s+\d|\))/m)
      o_results = match if match && !line.include?('mit Antwort')
      match = line.match(/Antwort\s+(.+)\s+([\d\.]+)/m)
      a_results = match if match
    end
    return nil if o_results.nil? || a_results.nil?
    {
      doctype: o_results[1].strip,
      originators: o_results[2].strip,
      answerers: a_results[1].strip,
      published_at: a_results[2]
    }
  end

  def self.extract_paper(item)
    fail 'NI [?]: called extract_paper with null parameter' if item.nil?
    details = extract_references_block(item)
    title = extract_title(details)
    fail 'NI [?]: no title element found' if title.nil?

    container = extract_container(details)
    fail "NI [?]: no container element found. Paper title: #{title}" if container.nil?

    link = extract_link(container)
    fail "NI [?]: no link element found. Paper title: #{title}" if link.nil?

    full_reference = extract_full_reference(link)
    is_answer = extract_is_answer(item)
    legislative_term, reference = extract_reference(full_reference)
    url = extract_url(link)
    meta = extract_meta(container)
    fail "NI [#{full_reference}]: no readable meta information found" if meta.nil?

    doctype = extract_doctype(meta[:doctype])

    ministries = []
    if doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
      originators = { people: [], parties: [meta[:originators]] }
    else
      originators = NamePartyExtractor.new(meta[:originators]).extract
    end
    ministries = [meta[:answerers]] unless meta[:answerers].nil?
    published_at = Date.parse(meta[:published_at])

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
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
    TYPE = 'Große Anfrage Mit Antwort;Kleine Anfrage Zur Schriftlichen Beantwortung Mit Antwort'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      mp = m.get SEARCH_URL
      search_form = mp.form '__form'
      fail 'Cannot get search form' if search_form.nil?

      # fill search form
      search_form.field_with(name: '__action').value = 6
      search_form.field_with(name: 'wplist').value = @legislative_term
      search_form.field_with(name: 'Suchzeile6').value = TYPE
      mp = m.submit(search_form)

      # Fail if no hits
      fail 'search returns no results' if mp.search('//tbody[@name="RecordRepeater"]').size == 0

      # retrieve new search form with more options
      search_form = mp.form '__form'
      fail 'Cannot switch view' if search_form.nil?

      search_form.field_with(name: '__action').value = 29
      search_form.field_with(name: 'ReportFormatListDisplay').value = 'Vollanzeige'
      # remove all the hidden "SelectedItems" input fields because NI doesn't seem to like long post requests
      search_form.fields.each do |f|
        search_form.delete_field!(f.name) if f.name == 'SelectedItems'
      end
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
