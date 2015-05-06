require 'date'

module BrandenburgLandtagScraper
  BASE_URL = 'http://www.parldok.brandenburg.de'
  # smaller searches or brandenburg times out
  # search five years for every half month
  SEARCH_PARTS = 5

  def self.get_dates(wp)
    # parse the dates from Wikipedia?
    # WP is index, startdate, enddate are values

    periods = [
      nil,
      nil,
      nil,
      ['1.09.1999', '30.09.2004'],
      ['1.09.2004', '30.09.2009'],
      ['1.09.2009', '30.09.2014'],
      ['1.09.2014', '30.09.2019']
    ]
    if !periods[wp].nil?
      start_time = Date.parse(periods[wp].first)
      end_time = Date.parse(periods[wp].last)
      # all dates from starttime to endtime
      dates = start_time.step(end_time).to_a
      # each sliced to approximatly equal length
      dates.each_slice((dates.size / SEARCH_PARTS.to_f).round).map do |date|
        [date.first, date.last]
      end
    else
      nil
    end
  end

  def self.extract_body(page)
    page.search('//body').first
  end

  def self.extract_detail_item(body)
    body.search('//table[@class="tabcol"]')[2]
  end

  def self.extract_overview_items(body)
    body.search('//span[@name="OFR_WWK4"]')
  end

  def self.extract_title(item)
    item.search('.//tr[2]/td[2]').text
  end

  def self.extract_full_reference(link)
    link.text
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_meta_row(item)
    item.at_css('table')
  end

  def self.extract_doctype(meta_block)
    if meta_block.text.include?('KlAnfr')
      Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif meta_block.text.include?('GrAnfr')
      Paper::DOCTYPE_MAJOR_INTERPELLATION # FIXME: does it work?
    end
  end

  def self.extract_originators(meta_text, doctype)
    if doctype == Paper::DOCTYPE_MINOR_INTERPELLATION
      # KlAnfr 123 Aaaaaa Bbbbbb (ABC), Cccccc Ddddddd (ABC) 11.12.2014 Drs 6/123 (1 S.)
      meta = meta_text.strip.match(/\s(\D+ \(.+\),?)\s+[\d\.]+\s+Drs/)
      return nil if meta.nil?
      NamePartyExtractor.new(meta[1]).extract
    else
      # GrAnfr 123 (ABC, ABC) 11.12.2014 Drs 6/123 (1 S.)
      parties = []
      meta_text.split('(')[1].split(')')[0].split(',').each{ |p| parties.push(p.strip) }
      { people: [], parties: parties }
    end
  end

  def self.extract_published_at(meta_text)
    s = meta_text.split('Antw   (LReg)  ')[1]
    date = s.match(/\d+\.\d+\.\d{4}/)
    Date.parse(date[0].to_s.gsub('.', '-'))
  end

  def self.extract_detail_paper(item)
    meta = extract_meta_row item
    doctype = extract_doctype(meta)
    return nil if doctype.nil?

    link = item.search('a').find { |el| el.text.include?('/') }
    fail '[?] Cannot get Link' if link.nil?
    # skip BePr
    return nil if !link.previous.text.include?('Drs')

    path = link.attributes['href'].value
    url = Addressable::URI.parse(BASE_URL + path).normalize.to_s
    full_reference = extract_full_reference(link)
    legislative_term, reference = extract_reference(full_reference)
    originators = extract_originators(meta.text, doctype)
    published_at = extract_published_at(meta.text)

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: extract_title(item),
      url: url,
      published_at: published_at,
      originators: originators,
      # answerers in pdf
      is_answer: true
    }
  end

  def self.extract_paper_overview(item)
    return nil if item.content.include?('BePr')
    full_reference = item.content.match(/\d+\/\d+/)[0]
    {
      legislative_term: full_reference.split('/').first,
      full_reference: full_reference,
      reference: full_reference.split('/').last,
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
      papers = []
      dates = BrandenburgLandtagScraper.get_dates @legislative_term
      fail 'WP=' + @legislative_term + ' is not configured'  if dates.nil?
      dates.each do |date|
        mp = m.get SEARCH_URL
        search_form = mp.form '__form'
        fail 'Cannot get search form' if search_form.nil?
        search_form.field_with(name: 'Suchzeile7').value = date.first.strftime('%e.%-m.%Y')
        search_form.field_with(name: 'Suchzeile8').value = date.last.strftime('%e.%-m.%Y')
        # fill search form
        search_form.field_with(name: '__action').value = 4
        search_form.field_with(name: 'wplist').value = @legislative_term
        search_form.field_with(name: 'Suchzeile6').value = TYPE
        search_form.field_with(name: 'maxtrefferlist1').options.find { |opt| opt.text.include? 'alle' }.select
        mp = m.submit(search_form)
        body = BrandenburgLandtagScraper.extract_body(mp)
        BrandenburgLandtagScraper.extract_overview_items(body).each do |item|
          begin
            paper = BrandenburgLandtagScraper.extract_paper_overview(item)
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
    SEARCH_URL = BASE_URL + '/starweb/LTBB/start.html'

    def scrape
      m = mechanize
      m.get SEARCH_URL
      mp = m.get(BASE_URL + '/starweb/LTBB/servlet.starweb?path=LTBB/lisshfl.web&id=LTBBWEBDOKFL&search=DART%3dD+AND+WP%3d' + @legislative_term.to_s + '+AND+DNR%2cKORD%3d' + @reference.to_s + '&format=WEBLANGFL')

      body = BrandenburgLandtagScraper.extract_body mp
      item = BrandenburgLandtagScraper.extract_detail_item body
      BrandenburgLandtagScraper.extract_detail_paper(item)
    end
  end
end