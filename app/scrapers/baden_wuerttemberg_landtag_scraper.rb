require 'date'

module BadenWuerttembergLandtagScraper
  BASE_URL = 'http://www.landtag-bw.de'
  DETAIL_URL = 'http://www.statistik-bw.de/OPAL'

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/cms/render/live/de/sites/LTBW/home/dokumente/die-initiativen/gesamtverzeichnis/contentBoxes/suche-initiative.html?'
    TYPES = ['KA', 'GA']

    def get_legislative_dates
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

    def scrape
      streaming = block_given?
      papers = []
      m = mechanize
      # to initialize session
      m.get SEARCH_URL
      legislative_site = get_legislative_dates
      legislative_start_end = extract_legislative_dates(legislative_site)
      legislative_period = get_legislative_period(legislative_start_end[0], legislative_start_end[1])

      # result_pages = get_search_urls(SEARCH_URL, legislative_period)
      # result_pages.each do |page|
      #   results = m.get page
      #   list = results.search('//div[@id="result"]//ol')
      #   puts list.inspect

      # end
    end

    def get_search_urls(search_url, legislative_period)
      urls = []
      TYPES.each do |type|
        single_url_type = 'searchInitiativeType=' + type + '&'
        legislative_period.each do |month|
          if years.first == year
            search_months = first_year
          elsif years.last == year
            search_months = final_year
          else
            search_months = months
          end
          single_url_year = 'searchYear=' + year + '&'
          search_months.each do |month|
            single_url_month = 'searchMonth=' + month
            urls.push(search_url + single_url_type + single_url_year + single_url_month)
          end
        end
      end
      urls
    end
  end

  class Detail < DetailScraper
  end
end