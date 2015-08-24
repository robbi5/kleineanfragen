require 'date'

module BadenWuerttembergLandtagScraper
  BASE_URL = 'http://www.landtag-bw.de'
  DETAIL_URL = 'http://www.statistik-bw.de/OPAL'

  def self.extract_result_blocks(page)
    list = page.search('//div[@id="result"]//ol')
    list.css('.result')
  end

  def self.extract_full_reference(div)
    div.at_css('p').text.gsub(/\s+/, '').gsub(/g/, '').match(/(.+)-.+Datum/)[1].gsub(/\p{Z}+/, ' ').strip
  end

  def self.extract_originator_party(div)
    div.at_css('p').text.gsub(/\s+/, '').match(/Urheber:(.+$)/)[1].gsub(/\p{Z}+/, ' ').strip
  end

  def self.extract_title(div)
    div.at_css('a').text.strip
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.build_detail_url(legislative_term, reference)
    DETAIL_URL + '/Ergebnis.asp?WP=' + legislative_term + '&DRSNR=' + reference
  end

  def self.get_detail_link(page)
    table = page.search('//table[@class="OPAL"]/tr')
    table.at_css('a')
  end

  def self.link_is_answer?(link)
    link.text.lstrip.match(/und\s+Antw/).size >= 1
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

  # FIXME: extract originator
  def self.extract_meta(link)
    url = link.attributes['href'].value
    match_results = link.text.lstrip.match(/(KlAnfr|GrAnfr)\s+.+\s+\d+\..+und\s+Antw\s+(.+)\s+Drs/)
    doctype = extract_doctype(match_results[1])

    {
      doctype: doctype,
      url: url,
      answerers: match_results[2].strip
    }
  end

  def self.extract_overview_paper(block)
    full_reference = extract_full_reference(block)
    legislative_term, reference = extract_reference(full_reference)
    title = extract_title(block)
    originator_party = extract_originator_party(block)

    detail_url = build_detail_url(legislative_term, reference)
    detail_page = m.get(detail_url)
    detail_link = get_detail_link(detail_page)
    fail "BW [#{full_reference}] is not an answer" unless link_is_answer?(detail_link)

    # Remaining parts come from Detail Scraper
    {
      full_reference: full_reference,
      legislative_term: legislative_term,
      reference: reference,
      title: title,
      # originator: people is set in detail scraper
      originator: { people: [], parties: [originator_party] },
      # answerer is set in detail scraper
      is_answer: true
    }
  end

  # FIXME: are originators not accessible? -> they are, see meta.
  def self.extract_detail_paper(page, detail_link, full_reference)
    legislative_term, reference = extract_reference(full_reference)
    title = extract_detail_title(page)
    meta = extract_meta(detail_link)
    doctype = meta[:doctype]
    url = meta[:url]
    ministries = [meta[:answerers]] unless meta[:answerers].nil?

    {
      full_reference: full_reference,
      legislative_term: legislative_term,
      reference: reference,
      title: title,
      doctype: doctype,
      url: url,
      is_answer: true,
      # for originators, see extract_overview_paper
      answerers: {
        ministries: ministries
      }
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/cms/render/live/de/sites/LTBW/home/dokumente/die-initiativen/gesamtverzeichnis/contentBoxes/suche-initiative.html?'
    TYPES = ['KA', 'GA']

    def get_legislative_dates_page
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
      until date >= end_date
        year = date.year
        month = date.month
        period.push([year, month])
        date = date.next_month
      end
      period
    end

    def self.get_search_urls(search_url, legislative_period, types)
      urls = []
      types.each do |type|
        single_url_type = 'searchInitiativeType=' + type + '&'
        legislative_period.each do |month|
          single_url_year = 'searchYear=' + month[0].to_s + '&'
          single_url_month = 'searchMonth=' + format('%02d', month[1])
          urls << search_url + single_url_type + single_url_year + single_url_month
        end
      end
      urls
    end

    # FIXME: too many BWLS
    def scrape
      streaming = block_given?
      papers = []
      m = mechanize
      legislative_dates = get_legislative_dates_page
      legislative_period = self.class.get_legislative_period(legislative_dates[0], legislative_dates[1])

      urls = self.class.get_search_urls(SEARCH_URL, legislative_period, TYPES)
      urls.each do |url|
        page = m.get url
        blocks = BadenWuerttembergLandtagScraper.extract_result_blocks(page)
        blocks.each do |block|
          begin
            paper = BadenWuerttembergLandtagScraper.extract_overview_paper(block)
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