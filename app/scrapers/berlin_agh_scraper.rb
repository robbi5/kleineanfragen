require 'date'

module BerlinAghScraper
  BASE_URL = 'http://pardok.parlament-berlin.de'

  def self.extract_body(page)
    page.search "//table[contains(@summary, 'Hauptbereich')]"
  end

  def self.extract_seperators(body)
    body.search('.//td[contains(@colspan, 3)]/..')[0...-1]
  end

  def self.extract_title(seperator)
    seperator.next_element.search('./td[2]/b').first.try(:text).try(:gsub, /\n/, ' ')
  end

  def self.extract_type(seperator)
    seperator.next_element.next_element.search('./td[2]').first.try(:text)
  end

  def self.extract_data_cell(seperator)
    # skip 3 rows:      title,       type,        keywords
    data_el = seperator.next_element.next_element.next_element.next_element
    data_el = data_el.next_element if data_el.search('a').size == 0 # location row
    data_el = data_el.next_element if data_el.search('a').size == 0 # subtitle row
    data_el.search('./td[2]').first
  end

  def self.extract_link(data_cell)
    data_cell.search('a').first
  end

  def self.extract_full_reference(link)
    link.text.match(/([\d\/]+)/).try(:[], 1)
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_names(data_cell)
    data_cell.at_css('a').previous_element.previous.text
  end

  def self.extract_ministry_line(data_cell)
    data_cell.search('a')[1].try(:previous_element).try(:previous).try(:text).try(:strip)
  end

  def self.extract_date(data_cell)
    data_cell.text.match(/.*vom ([\d\.]+)/m)[1]
  end

  def self.extract_paper(seperator)
    title = extract_title(seperator)
    fail '[?] no title found' if title.nil?

    data_cell = extract_data_cell(seperator)
    link = extract_link(data_cell)
    fail "[?] no link element found. Paper title: #{title}" if link.nil?

    full_reference = extract_full_reference(link)
    legislative_term, reference = extract_reference(full_reference)

    path = link.attributes['href'].value
    url = Addressable::URI.parse(BASE_URL + path).normalize.to_s

    names = extract_names(data_cell)
    originators = NamePartyExtractor.new(names).extract

    date = extract_date(data_cell)
    published_at = Date.parse(date)

    ministries = extract_ministry_line(data_cell).split(' ')

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

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/AHAB/servlet.starweb?path=AHAB/lisshfl.web&id=ahabfastlink&format=WEBVORGLFL&search='

    def supports_streaming?
      true
    end

    # FIXME: find search with pagination, add support for pagination
    def scrape
      streaming = block_given?
      mp = mechanize.get SEARCH_URL + CGI.escape("WP=#{@legislative_term} AND (etyp=schriftl*)")

      body = BerlinAghScraper.extract_body(mp)

      legterm = body.search("//th[contains(@class, 'gross2')]").inner_html.strip
      legislative_term = legterm.match(/(\d+). Wahlperiode/)[1]
      warn_broken(legislative_term.to_i != @legislative_term, 'legislative_term not correct', legislative_term)

      papers = []

      BerlinAghScraper.extract_seperators(body).each do |seperator|
        begin
          paper = BerlinAghScraper.extract_paper(seperator)
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

      papers unless streaming
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/starweb/AHAB/servlet.starweb?path=AHAB/lisshfl.web&id=ahabfastlink&format=WEBVORGLFL&search='

    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape('WP=' + @legislative_term.to_s + ' AND DNR=' + @reference.to_s)
      body = BerlinAghScraper.extract_body(mp)
      seperator = BerlinAghScraper.extract_seperators(body).first
      BerlinAghScraper.extract_paper(seperator)
    end
  end
end