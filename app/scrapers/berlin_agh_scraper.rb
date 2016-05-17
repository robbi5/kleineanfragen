require 'date'

module BerlinAghScraper
  BASE_URL = 'http://pardok.parlament-berlin.de'

  def self.extract_body(page)
    page.search("//table[contains(@class, 'tabcol')]").last
  end

  def self.extract_seperators(body)
    body.search('.//td[contains(@colspan, 3)]/..')[0...-1]
  end

  def self.extract_title(seperator)
    el = seperator.next_element.search('./td[2]/b').first
    return nil if el.nil?
    el.css('br').each { |br| br.replace ' ' }
    el.text
  end

  def self.extract_type(seperator)
    doctype_text = seperator.next_element.next_element.search('./td[2]').first.try(:text)
    if doctype_text.scan(/kleine/i).present?
      Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif doctype_text.scan(/große/i).present?
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    elsif doctype_text.scan(/schriftliche/i).present?
      Paper::DOCTYPE_WRITTEN_INTERPELLATION
    end
  end

  def self.extract_data_cell(seperator)
    # skip 3 rows:      title,       type,        keywords
    data_el = seperator.next_element.next_element.next_element.next_element
    data_el = data_el.next_element if data_el.search('a').size == 0 # location row
    data_el = data_el.next_element if data_el.search('a').size == 0 # subtitle row
    data_el.search('./td[2]').first
  end

  def self.extract_url(link)
    link.attributes['href'].try(:value)
  end

  def self.extract_first_link(data_cell)
    data_cell.search('a').first
  end

  def self.extract_link(answer_round)
    el = answer_round
    loop do
      el = el.next_element
      break if el.nil?
      return el if el.name == 'a' && el.text.include?('Drucksache')
    end
  end

  def self.extract_full_reference(link)
    link.text.match(/([\d\/]+)/).try(:[], 1)
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_names(data_cell)
    data_cell.elements.first.previous.text.strip
  end

  def self.extract_ministry_line(answer_round)
    line = answer_round.next_element.next_element.next
    line = line.next_element.next if line.text.include? 'Kommentar: '
    line.text.strip
  end

  def self.extract_ministries(ministry_line)
    ministry_line.split(/\s+\-|,/).map(&:strip).reject(&:empty?).uniq
  end

  def self.extract_date(link)
    link.next.text.match(/.*vom\s+([\d\.]+)/m).try(:[], 1)
  end

  def self.extract_last_date(data_cell)
    data_cell.text.match(/.*vom ([\d\.]+)/m)[1]
  end

  def self.extract_answer_round(data_cell)
    data_cell.search('u').each do |el|
      type = el.next_element.next.text.strip
      return el if type == 'Antwort'
    end
    nil
  end

  def self.extract_paper(seperator)
    title = extract_title(seperator)
    fail '[?] no title found' if title.nil?

    data_cell = extract_data_cell(seperator)

    answer_round = extract_answer_round(data_cell)
    fail "[?] no answer round found. Paper title: #{title}" if answer_round.nil?

    broken_paper = false
    link = extract_link(answer_round)
    if link.nil?
      # got broken paper
      link = extract_first_link(data_cell)
      broken_paper = true
    end
    fail "[?] no link element found. Paper title: #{title}" if link.nil?

    full_reference = extract_full_reference(link)
    legislative_term, reference = extract_reference(full_reference)

    path = link.attributes['href'].value
    url = Addressable::URI.parse(BASE_URL).join(path).normalize.to_s

    doctype = extract_type(seperator)
    fail "[#{full_reference}] no known doctype" if doctype.nil?

    names = extract_names(data_cell)
    originators = NamePartyExtractor.new(names).extract
    if doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
      originators = { people: [], parties: originators[:people] }
    end

    if broken_paper
      date = extract_last_date(data_cell)
    else
      date = extract_date(link)
    end
    published_at = Date.parse(date)

    ministry_line = extract_ministry_line(answer_round)
    fail "[#{full_reference}] no ministry line found" if ministry_line.nil?

    ministries = extract_ministries(ministry_line)

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title,
      url: url,
      published_at: published_at,
      originators: originators,
      is_answer: true,
      answerers: { ministries: ministries },
      source_url: Detail.build_search_url(legislative_term, reference)
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/AHAB/servlet.starweb?path=AHAB/lissh.web'
    TYPE = 'KLEINE ANFRAGE; SCHRIFTLICHE ANFRAGE; GROßE ANFRAGE; GROẞE ANFRAGE'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      # increase read timeout for berlin
      m.read_timeout = 120
      # get a session
      m.get BASE_URL + '/starweb/AHAB/'
      # get search page
      mp = m.get SEARCH_URL
      search_form = mp.form '__form'

      fail 'Cannot get search form' if search_form.nil?

      # fill search form
      search_form.field_with(name: '__action').value = 19
      search_form.field_with(name: 'wplist').value = @legislative_term
      search_form.field_with(name: 'Suchzeile6').value = TYPE
      search_form.field_with(name: 'maxtrefferlist1').options.find { |opt| opt.text.include? 'alle' }.select
      mp = m.submit(search_form)

      ## Fail if no hits
      # fail 'search returns no results' if mp.search('//span[@name="HitCountZero"]').size > 0

      # retrieve new search form with more options
      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 44
      search_form.field_with(name: 'ReportFormatListDisplay').value = 'Vorgaenge'
      mp = m.submit(search_form)

      body = BerlinAghScraper.extract_body(mp)

      legterm = body.at_css('th.gross2').text.strip
      legislative_term = legterm.match(/(\d+).\s+Wahlperiode/)[1]
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

  class Instant < Scraper
    SEARCH_URL = BASE_URL + '/starweb/AHAB/servlet.starweb?path=AHAB/lisshfl.web&id=ahabflprofi&format=WEBVORGLFL&search='

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      # increase read timeout for berlin
      m.read_timeout = 120
      mp = m.get self.class.build_search_url(@legislative_term)

      body = BerlinAghScraper.extract_body(mp)

      return nil if body.search("//div[contains(@name, 'ReportNotGenerated')]").size > 0

      legterm = body.at_css('th.gross2').text.strip
      legislative_term = legterm.match(/(\d+).\s+Wahlperiode/)[1]
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

    def self.build_search_url(legislative_term)
      SEARCH_URL + CGI.escape("WP=#{legislative_term} AND upd=x and etyp=schr*")
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/starweb/AHAB/servlet.starweb?path=AHAB/lisshfl.web&id=ahabfastlink&format=WEBVORGLFL&search='

    def scrape
      m = mechanize
      # increase read timeout for berlin
      m.read_timeout = 120
      mp = m.get self.class.build_search_url(@legislative_term, @reference)
      body = BerlinAghScraper.extract_body(mp)
      seperator = BerlinAghScraper.extract_seperators(body).first
      BerlinAghScraper.extract_paper(seperator)
    end

    def self.build_search_url(legislative_term, reference)
      SEARCH_URL + CGI.escape("WP=#{legislative_term} AND DNR=#{reference}")
    end
  end
end