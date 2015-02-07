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
        mp.search('//tbody[@name="RecordRepeater"]').each do |item|
          paper = RheinlandPfalzLandtagScraper.extract(item)
          next if paper.nil?
          if streaming
            yield paper
          else
            papers << paper
          end
        end

        # submit form for next page
        search_form = mp.form '__form'
        search_form.field_with(name: '__action').value = 48
        mp = m.submit(search_form)
        if mp.search('//a[@name="NextRecords"]').size == 0
          puts "Cannot find more pages: #{mp.content}"
          break
        end
      end
      papers unless streaming
    end
  end

  class Detail < Scraper
    SEARCH_URL = BASE_URL + '/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/LISSHFLMORE.web&id=LTRPOPALDOKFL&format=LISSH_MoreDokument_Report&search='

    def initialize(legislative_term, reference)
      @legislative_term = legislative_term
      @reference = reference
    end

    def full_reference
      @legislative_term.to_s + '/' + @reference.to_s
    end

    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape("(DART=D AND WP=#{@legislative_term} AND DNR,KORD=#{@reference})")
      item = mp.search('//tbody[@name="RecordRepeater"]').first
      RheinlandPfalzLandtagScraper.extract(item)
    end
  end

  # FIXME: move somewhere else
  def self.patron_session
    sess = Patron::Session.new
    sess.connect_timeout = 5
    sess.timeout = 60
    sess.headers['User-Agent'] = Rails.configuration.x.user_agent
    sess
  end

  # extract paper information
  def self.extract(item)
    title = item.search('./tr[@name="Repeat_WHET"]/td[2]').first.text
    container = item.search('./tr[@name="Repeat_Fund"]/td[3]').first

    # for broken records like 16D4556
    if container.nil?
      Rails.logger.warn "RP [?]: no meta information found. Paper title: #{title}"
      return
    end

    link = container.at_css('a')
    full_reference = link.text.strip
    url = link.attributes['href'].value
    legislative_term = full_reference.split('/').first
    reference = full_reference.split('/').last

    results = container.text.match(/Kleine Anfrage \d+ (.+) und Antwort (.+) ([\d\.]+) /)

    if results.nil?
      Rails.logger.warn "RP [#{full_reference}]: no readable meta information found"
      return
    end

    # not all papers are available
    resp = patron_session.head(url)
    if resp.status == 404 || resp.url.include?('error404.html')
      Rails.logger.warn "RP [#{full_reference}]: url throws 404"
      return
    end

    originators = NamePartyExtractor.new(results[1].strip).extract
    ministries = [results[2].strip]
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