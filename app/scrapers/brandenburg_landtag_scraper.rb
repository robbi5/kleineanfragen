require 'date'

module BrandenburgLandtagScraper
  BASE_URL = 'https://www.parlamentsdokumentation.brandenburg.de'
  START_URL = BASE_URL + '/starweb/LBB/ELVIS/index.html'

  # smaller searches or brandenburg times out
  # search five years for every half month
  SEARCH_PARTS = 5

  def self.get_daterange(options)
    ranges = {}
    options.each do |el|
      key = el.value
      braces = el.text.strip.match(/\s+\((.+)\)/)
      next if braces.nil?
      b = braces[1]
      if b.start_with? 'seit'
        # 6. Wahlperiode (seit 08.10.2014)
        range = [b.gsub(/seit\s+/, ''), nil]
      elsif b.include? '-'
        # 5. Wahlperiode (21.10.2009 - 08.10.2014)
        range = b.split(/\s+-\s+/)
      end
      ranges[key.to_i] = range
    end
    ranges
  end

  def self.get_dates(period)
    return nil if period.nil? || period.first.nil?
    start_time = Date.parse(period.first)
    end_time = period.last.nil? ? (Date.today + 1.day) : Date.parse(period.last)
    # all dates from starttime to endtime
    dates = start_time.step(end_time).to_a
    # each sliced to approximatly equal length
    dates.each_slice((dates.size / SEARCH_PARTS.to_f).round).map do |date|
      [date.first, date.last]
    end
  end

  def self.extract_body(page)
    page.search('//body').first
  end

  def self.extract_detail_item(body)
    extract_overview_items(body).first
  end

  def self.extract_overview_items(body)
    # use "Record Repeater" directly below "ReportGenerated",
    # in "HitCountReportConditional" are a lot of empty "Record Repeater"s
    body.search('//div[@name="ReportGenerated"][1]/div[@starweb_type="Record Repeater"][position() < last()]')
  end

  def self.extract_title(item)
    item.search('.//h4').text
  end

  def self.extract_doctype(meta_block)
    if meta_block.text.include?('Kleine Anfrage')
      Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif meta_block.text.match(/Gro.+?e Anfrage/)
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
  end

  def self.extract_answer_data(answer_text)
    m = answer_text.strip.match(/Antwort\s+\(.+?\)\s+([\d\.]+)\s+Drucksache\s+(\d+\/\d+)\s+/)
    {
      published_at: Date.parse(m[1]),
      full_reference: m[2]
    }
  end

  def self.extract_originators(originator_text)
    o = originator_text.match(/(.+)\s+([\d\.]+)\s+Drucksache\s+\d+\/\d+\s/)
    o[1].strip
  end

  def self.extract_paper(item)
    originator_row = item.at_css('div[name="Repeat_TYP"]')
    answer_row = item.at_css('div[name="Repeat_DBE"]')
    return nil if originator_row.nil? || answer_row.nil?
    link = answer_row.at_css('a[href$="pdf"]')
    answer_text_el = answer_row.at_css('.topic2')
    answer_text = answer_text_el.text.strip

    ad = extract_answer_data(answer_text)
    full_reference = ad[:full_reference]

    path = link.attributes['href'].value
    url = Addressable::URI.parse(BASE_URL).join(path).normalize.to_s

    type_row = originator_row.at_css('span[name="OFR_BASIS2"]')
    doctype = extract_doctype(type_row)

    originator_text = originator_row.at_css('span[name="OFR_BASIS3"]').text.strip
    o = extract_originators(originator_text)
    if doctype == Paper::DOCTYPE_MINOR_INTERPELLATION
      originators = NamePartyExtractor.new(o).extract
    elsif doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
      originators = NamePartyExtractor.new(o, NamePartyExtractor::FRACTION).extract
    end

    legislative_term, reference = full_reference.split('/')
    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: extract_title(originator_row),
      url: url,
      published_at: ad[:published_at],
      originators: originators,
      # answerers in pdf
      is_answer: true,
      source_url: Detail.build_search_url(legislative_term, reference)
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/LBB/ELVIS/servlet.starweb?path=LBB/ELVIS/LISSH.web&AdvancedSearch=yes'
    TYPE = 'ANTWORT' # 'Kleine Anfrage;Große Anfrage' doesn't contain answers

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize

      # initialize session
      mp = m.get START_URL

      form = mp.form 'SucheLISSH'
      fail 'Cannot get start page form' if form.nil?
      opt = form.field_with(name: 'LISSH_WP').options

      # extract dates from search select
      dateranges = BrandenburgLandtagScraper.get_daterange opt

      dates = BrandenburgLandtagScraper.get_dates dateranges[@legislative_term]
      fail "BB: Couldn't extract dates for legislative term #{@legislative_term}" if dates.nil?

      papers = []
      dates.reverse_each do |date|
        mp = m.get SEARCH_URL
        fail 'Starweb backend is down' if mp.body.include? 'STARWebInactive.htm'

        # navigate to extended search page
        redir_form = mp.form '__form'
        fail 'Cannot get redirection form' if redir_form.nil?
        redir_form.field_with(name: '__action').value = 39
        mp = m.submit(redir_form)

        search_form = mp.form '__form'
        fail 'Cannot get search form' if search_form.nil?

        # fill search form
        search_form.field_with(name: 'LISSH_WP_ADV').value = @legislative_term
        search_form.field_with(name: '__action').value = 72
        search_form.field_with(name: 'LISSH_DART_ADV').value = 'DRUCKSACHE'
        search_form.field_with(name: 'LISSH_DTYP').value = TYPE
        search_form.field_with(name: 'LISSH_DatumV').value = date.first.strftime('%e.%-m.%Y')
        search_form.field_with(name: 'LISSH_DatumB').value = date.last.strftime('%e.%-m.%Y')
        # search_form.field_with(name: 'LimitMaximumHitCount').options.find { |opt| opt.text.include? 'alle' }.select
        # all is broken, hardcode fixed value instead:
        search_form.field_with(name: 'LimitMaximumHitCount').value = 'S99{ITEMS -1:-100000}' # works on other starwebs
        mp = m.submit(search_form)

        search_form = mp.form '__form'
        fail 'Cannot get search form on result page' if search_form.nil?

        if mp.search('//div[@id="main"]/div[@class="panelStatus"]').size > 0
          fail 'Result page showed error'
        end

        # get more items
        search_form.field_with(name: '__action').value = 175
        search_form.field_with(name: 'NumPerSegment').options.find { |opt| opt.text.include? 'alle' }.select
        mp = m.submit(search_form)

        body = BrandenburgLandtagScraper.extract_body(mp)
        BrandenburgLandtagScraper.extract_overview_items(body).each do |item|
          begin
            paper = BrandenburgLandtagScraper.extract_paper(item)
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
      end
      papers unless streaming
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/starweb/LBB/ELVIS/servlet.starweb?path=LBB/ELVIS/LISSH.web&Standardsuche=yes&search='

    def scrape
      m = mechanize
      # initialize session
      m.get START_URL
      # get paper
      mp = m.get self.class.build_search_url(@legislative_term, @reference)
      form = mp.form('__form')
      form.field_with(name: '__action').value = 51
      mp = m.submit form

      body = BrandenburgLandtagScraper.extract_body(mp)

      item = BrandenburgLandtagScraper.extract_detail_item(body)
      fail 'Cannot get detail item' if item.nil?

      BrandenburgLandtagScraper.extract_paper(item)
    end

    def self.build_search_url(legislative_term, reference)
      SEARCH_URL + CGI.escape("WP=#{legislative_term} AND DNR=#{reference}")
    end
  end
end