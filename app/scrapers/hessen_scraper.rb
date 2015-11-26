module HessenScraper
  BASE_URL = 'http://starweb.hessen.de'

  def self.extract_blocks(page)
    page.search('//*[@id="container"]/form/div/div/div/table/tbody')
  end

  def self.extract_detail_block(detail_page)
    detail_page.at_css('#listTable pre')
  end

  def self.extract_reference(block)
    block.at_css('span[name="OFR_Drs"]').content.split('/')
  end

  def self.extract_interpellation_type(block)
    doc_type = block.at_css('span[name="OFR_Vorgtyp"]')
    doc_type = doc_type.content.split('/')[1]

    if doc_type.start_with?('Kleine')
      return Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif doc_type.start_with?('Große')
      return Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
    nil
  end

  def self.extract_title(block)
    span = block.at_css('span[name="OFR_Betreff"]')
    title = span.at_css('.textlink')
    title = span.at_css('.textLink') if title.nil?
    title.content.gsub(/\p{Z}+/, ' ').gsub(/\n/, ' ').gsub(/\s+/, ' ').strip
  end

  def self.extract_paper(block)
    leg, ref = extract_reference(block)
    {
      legislative_term: leg,
      full_reference: [leg, ref].join('/'),
      reference: ref,
      doctype: extract_interpellation_type(block),
      title: extract_title(block),
      # is_answer: true # -> detail scraper
    }
  end

  def self.extract_detail_result(page)
    page.search('//tbody[@name="RecordRepeatStart"]').first
  end

  def self.extract_detail_paper(block)
    response_line = extract_answer_line(block.content)
    return nil if response_line.nil?

    leg, ref = extract_detail_reference(block)
    date = get_date_from_detail_line(response_line)
    {
      legislative_term: leg,
      full_reference: [leg, ref].join('/'),
      reference: ref,
      doctype: extract_detail_type(block),
      title: extract_detail_title(block),
      published_at: date,
      originators: extract_originators(extract_originator_text(block)),
      # unanswered papers often have a future publishing date
      is_answer: (date <= Date.today)
    }
  end

  def self.extract_detail_type(detail_block)
    textblock = detail_block.child.next.next.text.strip
    if !textblock.match(/(^|\W)KlAnfr\W/).nil?
      return Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif !textblock.match(/(^|\W)GrAnfr\W/).nil?
      return Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
    nil
  end

  def self.extract_detail_title(detail_block)
    title = detail_block.at_css('b').text
    title.gsub(/\p{Z}+/, ' ').gsub(/\n/, ' ').gsub(/\s+/, ' ').strip.gsub(/-\s+/, '')
  end

  def self.extract_originator_text(detail_block)
    textblock = detail_block.child.next.next.text
    textblock.match(/(?:GrAnfr|KlAnfr)(.+)\s+\d/m)[1]
  end

  def self.extract_originators(text)
    text = text.sub('KlAnfr', '').sub('GrAnfr', '')
    lines = text.split("\n")
    first_date_matched = false
    lines = lines.map do |line|
      # we can ignore everything after a line with a date
      first_date_matched = true if !get_matches_for_date_pattern(line).empty?
      line.gsub(/\p{Z}+/, ' ').strip
      line = nil if first_date_matched
      line
    end
    originators = lines.reject(&:nil?).join(' ')
    contains_faction = !originators.match('Fraktion').nil?
    is_single_originator = originators.match(',').nil?
    if contains_faction && is_single_originator
      NamePartyExtractor.new(originators, NamePartyExtractor::FACTION).extract
    else
      NamePartyExtractor.new(originators, NamePartyExtractor::REVERSED_NAME_PARTY).extract
    end
  end

  def self.extract_answer_line(text)
    text.split("\n").each do |s|
      s = s.gsub(/\p{Z}+/, ' ').strip
      return s if s.include?('Antw ') || s.include?('und Antw')
    end
    nil
  end

  def self.extract_detail_reference(block)
    block.at_css('a').content.split('/')
  end

  def self.get_matches_for_date_pattern(line)
    line.scan(/\d{2}\.\d{2}\.\d{4}/)
  end

  def self.get_date_from_detail_line(line)
    matches = get_matches_for_date_pattern(line)
    return nil if matches.nil?
    Date.parse(matches.last)
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/LIS/servlet.starweb?path=LIS/PdPi_FL.web'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      search_url = SEARCH_URL + "&wp=WP#{@legislative_term}&search=((UTYP1=GR+OR+KL)+AND+ANTWEIN+NOT+(!+OR+%22%22))"
      mp = mechanize.get search_url
      blocks = HessenScraper.extract_blocks(mp)
      papers = []
      blocks.each do |block|
        begin
          paper = HessenScraper.extract_paper(block)
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

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/starweb/LIS/servlet.starweb?path=LIS/PdPi_FLMore19.web&search='

    def scrape
      m = mechanize
      mp = m.get SEARCH_URL + CGI.escape("WP=#{@legislative_term} and DRSNRU,ANTW=\"#{full_reference}\"")

      detail_block = HessenScraper.extract_detail_block(mp.root)
      paper = HessenScraper.extract_detail_paper(detail_block)
      return nil if paper.nil?

      if paper[:doctype] == Paper::DOCTYPE_MINOR_INTERPELLATION
        mp = m.click(detail_block.at_css('a')) # first link
      elsif paper[:doctype] == Paper::DOCTYPE_MAJOR_INTERPELLATION
        mp = m.click(detail_block.css('a')[1]) # second link
      end
      pdf_path = mp.search('//a[contains(@href, ".pdf")]').first[:href]
      paper[:url] = Addressable::URI.parse(BASE_URL).join(pdf_path).normalize.to_s

      paper
    end
  end
end