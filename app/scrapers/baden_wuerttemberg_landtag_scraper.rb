require 'date'

module BadenWuerttembergLandtagScraper
  BASE_URL = 'http://www.landtag-bw.de'
  DETAIL_URL = 'http://www.statistik-bw.de/OPAL'

  def self.extract_result_blocks(page)
    if page.search('//p[@class="noResult"]').size > 0
      # got no results for this page
      # have to exit here, because there is an <ol> - but that only displays some "older initiatives"
      return []
    end
    list = page.search('//div[@id="result"]//ol').first
    list.css('.result')
  end

  def self.extract_overview_meta(div)
    text = div.at_css('p').text.strip.gsub(/\p{Z}+/, ' ').gsub(/\n/, ' ').gsub(/\s+/, ' ')

    m = text.match(/([\d\/]+)\s+-\s+Datum:\s+([\d\.]+)\s+-\s+Art:\s+(.+)\s+-\s+Urheber:\s+(.+)/)
    {
      full_reference: m[1],
      published_at: Date.parse(m[2]),
      doctype: m[3],
      originator_party: m[4]
    }
  end

  def self.extract_title(div)
    div.at_css('a').text.strip
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.build_detail_url(legislative_term, reference)
    DETAIL_URL + "/Ergebnis.asp?WP=#{legislative_term}&DRSNR=#{reference}"
  end

  def self.get_detail_link(page)
    table = page.search('//table[@class="OPAL"]/tr')
    table.at_css('a')
  end

  def self.link_is_answer?(link)
    !link.text.strip.match(/und\s+Antw/).nil?
  end

  def self.extract_doctype(match_result)
    case match_result.downcase
    when 'klanfr'
      Paper::DOCTYPE_MINOR_INTERPELLATION
    when 'granfr'
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
  end

  def self.extract_detail_title(page)
    table = page.search('//table[@class="OPAL"]')
    table_rows = table.css('tr')
    table_rows.each do |row|
      if row.at_css('td').text == 'Betreff:'
        return row.element_children[1].text
      end
    end
    nil
  end

  def self.extract_meta(meta_text)
    match_results = meta_text.lstrip.match(/(KlAnfr?|GrAnfr)\s+(.+)\s+([\d\.]+)\s+und\s+Antw\s+(.+)\s+Drs/)
    doctype = extract_doctype(match_results[1])
    # when multiple originators exist, remove "and others" - we extract the other names later
    names = match_results[2].gsub(/\s+(?:u.a.|u.u.)/, '').strip
    if doctype == Paper::DOCTYPE_MINOR_INTERPELLATION
      originators = NamePartyExtractor.new(names, NamePartyExtractor::NAME_PARTY_COMMA).extract
    elsif doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
      parties = names.split(',').map(&:strip)
      originators = { people: [], parties: parties }
    end

    {
      doctype: doctype,
      published_at: Date.parse(match_results[3]),
      originators: originators,
      answerers: { ministries: clean_ministries(match_results[4]) }
    }
  end

  def self.clean_ministries(ministries)
    ministries.gsub("\n", ' ').gsub(' und', ',').split(',').map(&:strip)
  end

  def self.extract_overview_paper(m, block, type)
    meta = extract_overview_meta(block)
    full_reference = meta[:full_reference]
    legislative_term, reference = extract_reference(full_reference)
    title = extract_title(block)

    detail_page = m.get build_detail_url(legislative_term, reference)
    detail_link = get_detail_link(detail_page)
    return nil if detail_link.nil? || !link_is_answer?(detail_link)

    {
      full_reference: full_reference,
      legislative_term: legislative_term,
      reference: reference,
      doctype: type,
      title: title,
      # url is set in detail scraper
      published_at: meta[:published_at],
      # originator: people is set in detail scraper
      originators: { people: [], parties: [meta[:originator_party]] },
      # answerers is set in detail scraper
      is_answer: true
    }
  end

  def self.extract_detail_paper(page, detail_link, full_reference)
    legislative_term, reference = extract_reference(full_reference)
    title = extract_detail_title(page)
    url = link.attributes['href'].value
    meta = extract_meta(detail_link.text)

    {
      full_reference: full_reference,
      legislative_term: legislative_term,
      reference: reference,
      doctype: meta[:doctype],
      title: title,
      url: url,
      published_at: meta[:published_at],
      is_answer: true,
      originators: meta[:originators],
      answerers: meta[:answerers]
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/cms/render/live/de/sites/LTBW/home/dokumente/die-initiativen/gesamtverzeichnis/contentBoxes/suche-initiative.html?'
    TYPES = {
      Paper::DOCTYPE_MINOR_INTERPELLATION => 'KA',
      Paper::DOCTYPE_MAJOR_INTERPELLATION => 'GA'
    }

    def supports_streaming?
      true
    end

    def get_legislative_dates
      m = mechanize
      mp = m.get DETAIL_URL + '/'
      extract_legislative_dates(mp)
    end

    def extract_legislative_dates(legislative_page)
      select_options = legislative_page.form.field_with(name: 'WP').options
      select_options.each do |option|
        if option.value.to_i == @legislative_term
          period = option.text.match(/\d.+ Wahlperiode \((.+)-(.+)\)/)
          return [Date.parse(period[1]), Date.parse(period[2])]
        end
      end
      nil
    end

    def self.get_legislative_period(start_date, end_date)
      period = []
      date = start_date
      until date >= end_date || date > Date.today
        year = date.year
        month = date.month
        period.push([year, month])
        date = date.next_month
      end
      period
    end

    def self.get_search_urls(search_url, legislative_period, type)
      urls = []
      single_url_type = 'searchInitiativeType=' + type + '&'
      # reversed, so current papers get loaded first
      legislative_period.reverse_each do |month|
        single_url_year = 'searchYear=' + month[0].to_s + '&'
        single_url_month = 'searchMonth=' + format('%02d', month[1])
        urls << search_url + single_url_type + single_url_year + single_url_month
      end
      urls
    end

    def scrape
      streaming = block_given?
      papers = []
      m = mechanize
      legislative_dates = get_legislative_dates
      legislative_period = self.class.get_legislative_period(legislative_dates[0], legislative_dates[1])

      TYPES.each do |type, url_type|
        urls = self.class.get_search_urls(SEARCH_URL, legislative_period, url_type)
        urls.each do |url|
          page = m.get url
          blocks = BadenWuerttembergLandtagScraper.extract_result_blocks(page)
          blocks.each do |block|
            begin
              paper = BadenWuerttembergLandtagScraper.extract_overview_paper(m, block, type)
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
      end
      papers unless streaming
    end
  end

  class Detail < DetailScraper
    def scrape
      m = mechanize
      page = m.get BadenWuerttembergLandtagScraper.build_detail_url(@legislative_term, @reference)
      detail_link = BadenWuerttembergLandtagScraper.get_detail_link(page)

      BadenWuerttembergLandtagScraper.extract_detail_paper(page, detail_link, full_reference)
    end
  end
end