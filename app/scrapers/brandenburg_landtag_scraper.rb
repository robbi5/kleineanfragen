require 'date'

module BrandenburgLandtagScraper
  BASE_URL = 'http://www.parldok.brandenburg.de'

  def self.extract_body(page)
    page.search("//table[contains(@summary, 'Report')]").first
  end

  def self.extract_items(body)
    items = body.css('table.tabcol')
    items.shift
    items
  end

  def self.extract_title(item)
    item.search('.//tr[4]/td[2]').first.text
  end

  def self.extract_full_reference(link)
    link.text
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_meta_block(item)
    item.at_css('table td+td')
  end

  def self.extract_meta_rows(element)
    data = []
    element.search('br').each do |br|
      frag = Nokogiri::HTML.fragment('')
      el = br
      loop do
        el = el.next
        break if el.nil? || el.try(:name) == 'br'
        frag << el.clone
      end
      data << frag
    end
    data
  end

  def self.extract_doctype(meta_block)
    if meta_block.text.include?('KlAnfr')
      Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif meta_block.text.include?('GrAnfr')
      Paper::DOCTYPE_MAJOR_INTERPELLATION # FIXME: does it work?
    end
  end

  def self.extract_originators(meta_row)
    # KlAnfr 123 Aaaaaa Bbbbbb (ABC), Cccccc Ddddddd (ABC) 11.12.2014 Drs 6/123 (1 S.)
    meta = meta_row.text.strip.match(/\s(\D+ \(.+\),?)\s+[\d\.]+\s+Drs/)
    return nil if meta.nil?
    NamePartyExtractor.new(meta[1]).extract
  end

  def self.extract_published_at(meta_row)
    date = meta_row.at_css('a').previous.text.match(/\s+([\d\.]+)\s+/)
    Date.parse(date[1])
  end

  def self.extract_paper(item)
    title = extract_title(item)
    data_el = extract_meta_block(item)
    # Skip MdlAnfr
    doctype = extract_doctype(data_el)
    return nil if doctype.nil?

    data = extract_meta_rows(data_el)

    link = data.last.search('a').find { |el| el.text.include?('/') }
    fail '[?] Cannot get Link' if link.nil?
    # skip BePr
    return nil if !link.previous.text.include?('Drs')

    path = link.attributes['href'].value
    url = Addressable::URI.parse(BASE_URL + path).normalize.to_s
    full_reference = extract_full_reference(link)
    legislative_term, reference = extract_reference(full_reference)
    originators = extract_originators(data.first)
    published_at = extract_published_at(data.last)

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title,
      url: url,
      published_at: published_at,
      originators: originators,
      # answerers in pdf
      is_answer: true
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/LTBB/servlet.starweb?path=LTBB/lissh.web'
    TYPE = 'ANTWORT' # 'Kleine Anfrage;Große Anfrage' doesn't contain answers

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      # get search page
      mp = m.get SEARCH_URL
      search_form = mp.form '__form'

      fail 'Cannot get search form' if search_form.nil?

      # fill search form
      search_form.field_with(name: '__action').value = 4
      search_form.field_with(name: 'wplist').value = @legislative_term
      search_form.field_with(name: 'Suchzeile6').value = TYPE
      search_form.field_with(name: 'maxtrefferlist1').options.find { |opt| opt.text.include? 'alle' }.select
      mp = m.submit(search_form)

      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 29
      search_form.field_with(name: 'ReportFormatListDisplay').value = 'Vorgaenge'
      page = m.submit(search_form)

      body = BrandenburgLandtagScraper.extract_body(page)

      papers = []
      BrandenburgLandtagScraper.extract_items(body).each do |item|
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
      papers unless streaming
    end
  end

  def self.extract_rss_date(title)
    # Antwort (LReg) Drucksache 6/1001 27.03.2015 (5 S.)
    meta = title.match(/Drucksache.+\s([\d\.]+)\s/)
    return nil if meta.nil?
    Date.parse(meta[1])
  end

  def self.extract_rss_url(description)
    data = description.match(/\shref="(.*)"\s/)
    return nil if data.nil?
    Addressable::URI.parse(BASE_URL + data[1]).normalize.to_s
  end

  class Detail < DetailScraper
    # using rss/xml export
    SEARCH_URL = BASE_URL + '/starweb/LTBBRSS/servlet.starweb?path=LTBBRSS/LTBBProfilRSS.web&format=DokumentUP&search='

    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape("DART=D AND WP=#{@legislative_term} AND DNR,KORD=#{@reference}")
      title = mp.search('//title').first.text
      desc = mp.search('//description').first.text
      fail "[BB #{full_reference}] Cannot get metadata" if title.blank? || desc.blank?
      published_at = BrandenburgLandtagScraper.extract_rss_date(title)
      fail "[BB #{full_reference}] Cannot get published_at" if published_at.nil?
      url = BrandenburgLandtagScraper.extract_rss_url(desc)

      {
        legislative_term: @legislative_term,
        full_reference: full_reference,
        reference: @reference,
        title: title,
        published_at: published_at,
        url: url,
        # no originator or answerers in feed
        is_answer: nil
      }
    end
  end
end