require 'date'

module BadenWuerttembergLandtagScraper
  BASE_URL = 'http://www.landtag-bw.de'
  DETAIL_URL = 'http://www.statistik-bw.de/OPAL'

  def self.extract_result_divs(page)
    list = page.search('//div[@id="result"]//ol')
    list.css('.result')
  end

  def self.extract_full_reference(div)
    div.at_css('p').text.gsub(/\s+/, "").match(/(.+)-.+Datum/)[1].gsub(/\p{Z}+/, ' ').strip
  end

  def self.extract_title(div)
    div.at_css('a').text.strip
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.build_detail_url(full_reference)
    legislative_term, reference = extract_reference(full_reference)
    url = DETAIL_URL + '/Ergebnis.asp?WP=' + legislative_term + '&DRSNR=' + reference
    url
  end

  def self.get_detail_url(check_answer_url)
    m = mechanize
    m.get check_answer_url
  end

  def self.get_detail_link(page)
    table = page.search('//table[@class="OPAL"]/tr')
    table.at_css('a')
  end

  def self.check_for_answer(link)
    link.text.lstrip.match(/und\s+Antw/).size >= 1
  end

  def self.extract_meta(link)
    url = link.attributes['href'].value
    match_results = link.text.lstrip.match(/(KlAnfr|GrAnfr)\s+(.+)\s+\d+\..+und\s+Antw\s+(.+)\s+Drs/)
    doctype = match_results[1]
    case doctype.downcase
    when 'klanfr'
      doctype = Paper::DOCTYPE_MINOR_INTERPELLATION
    when 'granfr'
      doctype = Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
    {
      doctype: doctype,
      url: url,
      originators: match_results[2].strip,
      answerers: {
        ministries: match_results[3].strip
      }
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/cms/render/live/de/sites/LTBW/home/dokumente/die-initiativen/gesamtverzeichnis/contentBoxes/suche-initiative.html?'
    TYPES = ['KA', 'GA']

    def get_legislative_dates_page
      m = mechanize
      m.get DETAIL_URL
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
      until date >= end_date do
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
          if month[1] < 10
            single_url_month = 'searchMonth=0' + month[1].to_s
          else
            single_url_month = 'searchMonth=' + month[1].to_s
          end
          urls.push(search_url + single_url_type + single_url_year + single_url_month)
        end
      end
      urls
    end

    def scrape
      streaming = block_given?
      papers = []
      m = mechanize
      # to initialize session
      m.get SEARCH_URL
      legislative_site = get_legislative_dates_page
      legislative_start_end = extract_legislative_dates(legislative_site)
      legislative_period = get_legislative_period(legislative_start_end[0], legislative_start_end[1])

      result_pages = get_search_urls(SEARCH_URL, legislative_period, TYPES)
      result_pages.each do |page|
        results = m.get page
        result_divs = results.extract_result_divs(page)
        result_divs.each do |div|
          # full_reference = extract_full_reference(div)
        end
      end
    end
  end

  class Detail < DetailScraper
  end
end