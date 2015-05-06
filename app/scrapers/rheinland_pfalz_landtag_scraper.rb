module RheinlandPfalzLandtagScraper
  BASE_URL = 'http://opal.rlp.de'

  def self.extract_records(page)
    page.search('//tbody[@name="RecordRepeater"]')
  end

  def self.extract_detail_block(page)
    page.search('./tr[@name="Repeat_Fund"]/td[3]').first
  end

  def self.extract_title(block)
    block.search('./tr[@name="Repeat_WHET"]/td[2]').first.text
  end

  def self.extract_link(container)
    container.at_css('a')
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

  def self.extract_ministries(ministry_line)
    ministry_line.split(/Ministerium/)
      .reject(&:empty?)
      .map { |s| "Ministerium #{s.strip.gsub(/\s*,$/, '')}" }
      .uniq
  end

  def self.extract_meta(meta_row)
    differentiation = meta_row.text.match(/(Kleine|Große)\s+Anfrage/m)
    if differentiation[1].downcase == 'kleine'
      link = extract_link(meta_row)
      results = meta_row.text.match(/Kleine\s+Anfrage\s+\d+\s+(.+?)\s+und\s+Antwort\s+(.+?)\s+([\d\.]+)\s+/)
      return nil if results.nil?
      {
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        originators: results[1].strip,
        answerers: results[2].strip,
        published_at: results[3],
        link: link
      }
    else
      o_results, a_results = [nil, nil]
      link = nil
      last_line = nil
      meta_row.children.each do |line|
        match = line.text.match(/Große\s+Anfrage\s+(.+)\s+\d+\./)
        o_results = match if match && !line.text.include?('Antwort')
        match = line.text.match(/Antwort\s+(.+)\s+([\d\.]+) /m)
        a_results = match if match && !line.text.include?('Ergänzung')
        if link.nil?
          link = line if !last_line.nil? && last_line.text.include?('Antwort')
          last_line = line
        end
      end
      return nil if o_results.nil? || a_results.nil?
      originators = o_results[1].split(',').map(&:strip)
      {
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        originators: originators,
        answerers: a_results[1].strip,
        published_at: a_results[2],
        link: link
      }
    end
  end

  def self.extract_paper(item, check_pdf: true)
    title = extract_title(item)
    meta_row = extract_detail_block(item)

    # for broken records like 16D4556
    fail "RP [?]: no meta information found. Paper title: #{title}" if meta_row.nil?

    meta = extract_meta(meta_row)

    fail "RP [?]: no link element found. Paper title: #{title}" if meta[:link].nil?

    full_reference = extract_full_reference(meta[:link])
    url = extract_url(meta[:link])
    legislative_term, reference = extract_reference(full_reference)

    # not all papers are available
    if check_pdf
      begin
        resp = Scraper.patron_session.head(url)
      rescue => e
        raise "RP [#{full_reference}]: url throwed #{e}"
      end
      if resp.status == 404 || resp.url.include?('error404.html')
        fail "RP [#{full_reference}]: url throws 404"
      end
    end

    fail "NI [#{full_reference}]: no readable meta information found" if meta.nil?

    doctype = meta[:doctype]

    ministries = []
    if doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
      originators = { people: [], parties: meta[:originators] }
    else
      originators = NamePartyExtractor.new(meta[:originators]).extract
    end
    ministries = extract_ministries(meta[:answerers]) unless meta[:answerers].nil?
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
      is_answer: true,
      answerers: { ministries: ministries }
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/LISSH.web'
    TYPE = 'KLEINE ANFRAGE UND ANTWORT; ANTWORT'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      mp = m.get SEARCH_URL
      search_form = mp.form '__form'
      fail 'search form missing' if search_form.nil?

      # fill search form
      search_form.field_with(name: '__action').value = 19
      search_form.field_with(name: '02_LISSH_WP').value = @legislative_term
      search_form.field_with(name: '05_LISSH_DTYP').value = TYPE
      mp = m.submit(search_form)

      # retrieve new search form with more options
      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 20
      search_form.field_with(name: 'LimitMaximumHitCount').options.find { |opt| opt.text.include? 'alle' }.select

      # Fail if no hits
      fail 'search returns no results' if mp.search('//span[@name="HitCountZero"]').size > 0

      mp = m.submit(search_form)

      papers = []
      loop do
        RheinlandPfalzLandtagScraper.extract_records(mp).each do |item|
          begin
            paper = RheinlandPfalzLandtagScraper.extract_paper(item)
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

        # submit form for next page
        break if mp.search('//a[@name="NextRecords"]').size == 0
        search_form = mp.form '__form'
        search_form.field_with(name: '__action').value = 48
        mp = m.submit(search_form)
      end
      papers unless streaming
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/LISSHFLMORE.web&id=LTRPOPALDOKFL&format=LISSH_MoreDokument_Report&search='

    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape("(DART=D AND WP=#{@legislative_term} AND DNR,KORD=#{@reference})")
      item = RheinlandPfalzLandtagScraper.extract_records(mp).first
      RheinlandPfalzLandtagScraper.extract_paper(item)
    end
  end
end