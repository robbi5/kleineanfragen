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
    title.content.gsub(/\p{Z}+/, ' ').strip
  end

  def self.extract_originator_text(detail_block)
    detail_block.child.next.next.text
  end

  def self.extract_paper(block)
    leg, ref = extract_reference(block)
    {
      legislative_term: leg,
      full_reference: [leg, ref].join('/'),
      reference: ref,
      doctype: extract_interpellation_type(block),
      title: extract_title(block),
      is_answer: true
    }
  end

  def self.extract_result_from_search(page)
    page.search('//tbody[@name="RecordRepeatStart"]').first
  end

  def self.extract_originators(text)
    text = text.sub('KlAnfr', '').sub('GrAnfr', '')
    lines = text.split("\n")
    first_date_matched = false
    lines = lines.map do |line|
      # we can ignore everything after a line with a date
      first_date_matched = true if !get_matches_for_date_pattern(line).nil?
      line.gsub(/\p{Z}+/, ' ').strip
      line = nil if first_date_matched
      line
    end
    originators = lines.reject(&:nil?).join(' ')
    NamePartyExtractor.new(originators, NamePartyExtractor::REVERSED_NAME_PARTY).extract
  end

  def self.extract_answer_line(text)
    text.split("\n").each do |s|
      s = s.gsub(/\p{Z}+/, ' ').strip
      return s if s.include?('Antw') || s.include?('und Antw')
    end
    nil
  end

  def self.get_matches_for_date_pattern(line)
    /\d{2}\.\d{2}\.\d{4}/.match line
  end

  def self.get_date_from_detail_line(line)
    matches = get_matches_for_date_pattern(line)
    return nil if matches.nil?
    Date.parse(matches[(matches.length - 1)])
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
    SEARCH_URL = BASE_URL + '/starweb/LIS/Pd_Eingang.htm'

    def scrape
      m = mechanize
      mp = m.get SEARCH_URL
      mp = m.click(mp.link_with(text: 'Suche'))

      form = mp.form '__form'
      form.field_with(name: 'QuickSearchLine').value = full_reference
      form.field_with(name: '__action').value = 61
      mp = form.click_button

      result = HessenScraper.extract_result_from_search(mp)
      paper = HessenScraper.extract_paper(result)

      form = mp.form '__form'
      form.field_with(name: '__action').value = 121
      form.field_with(name: 'ReportFormatListValues').value = 'PdPiMoreReport'
      mp = m.submit(form)

      detail_block = HessenScraper.extract_detail_block(mp.search('//div[@id="inhalt"]'))
      response_line = HessenScraper.extract_answer_line(detail_block.content)
      return nil if response_line.nil?

      paper[:published_at] = HessenScraper.get_date_from_detail_line(response_line)
      paper[:originators] = HessenScraper.extract_originators(HessenScraper.extract_originator_text(detail_block))
      if paper[:doctype] == Paper::DOCTYPE_MINOR_INTERPELLATION
        mp = m.click(detail_block.at_css('a'))
        paper[:url] = BASE_URL + mp.search('//a').first[:href]
      elsif paper[:doctype] == Paper::DOCTYPE_MAJOR_INTERPELLATION
        mp = m.click(detail_block.css('a')[1])
        paper[:url] = BASE_URL + mp.search('//a')[1][:href]
      end

      paper
    end
  end
end