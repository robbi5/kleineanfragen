module RheinlandPfalzLandtagScraper
  BASE_URL = 'http://opal.rlp.de'

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/LISSH.web'
    TYPE = 'KLEINE ANFRAGE UND ANTWORT'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      mp = m.get SEARCH_URL
      search_form = mp.form '__form'
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

  # FIXME: move somewhere else
  def self.patron_session
    sess = Patron::Session.new
    sess.connect_timeout = 8
    sess.timeout = 60
    sess.headers['User-Agent'] = Rails.configuration.x.user_agent
    sess
  end

  def self.extract_records(page)
    page.search('//tbody[@name="RecordRepeater"]')
  end

  # extract paper information
  def self.extract_paper(item, check_pdf: true)
    title = item.search('./tr[@name="Repeat_WHET"]/td[2]').first.text
    container = item.search('./tr[@name="Repeat_Fund"]/td[3]').first

    # for broken records like 16D4556
    fail "RP [?]: no meta information found. Paper title: #{title}" if container.nil?

    link = container.at_css('a')
    fail "RP [?]: no link element found. Paper title: #{title}" if link.nil?

    full_reference = link.text.strip
    url = link.attributes['href'].value
    legislative_term = full_reference.split('/').first
    reference = full_reference.split('/').last

    results = container.at_css('a').previous.text.match(/Kleine Anfrage \d+ (.+) und Antwort (.+) ([\d\.]+) /)
    fail "RP [#{full_reference}]: no readable meta information found" if results.nil?

    # not all papers are available
    if check_pdf
      begin
        resp = patron_session.head(url)
      rescue => e
        raise "RP [#{full_reference}]: url throwed #{e}"
      end
      if resp.status == 404 || resp.url.include?('error404.html')
        fail "RP [#{full_reference}]: url throws 404"
      end
    end

    originators = NamePartyExtractor.new(results[1].strip).extract
    ministry_line = results[2].strip
    ministries = ministry_line.split('Ministerium').map { |m| m.sub(/,\s*$/, '').sub(/^\s/, 'Ministerium ') }.select { |m| !m.blank? }
    published_at = Date.parse(results[3])

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      title: title,
      url: url,
      published_at: published_at,
      originators: originators,
      answerers: { ministries: ministries }
    }
  end
end