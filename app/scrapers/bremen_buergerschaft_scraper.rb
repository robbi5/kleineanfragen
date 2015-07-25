require 'date'

module BremenBuergerschaftScraper
  BASE_URL = 'https://www.bremische-buergerschaft.de'
  TYPES = 'KlAnfr u. AntwSen;MdS Senat (Antwort)'

  def self.extract_results(table)
    table.css('tr')
  end

  def self.extract_full_reference(tr)
    tr.element_children[0].text.strip
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_doctype(tr)
    doctype = tr.element_children[1].text.match(/(KlAnfr|MdS Senat)/)

    if doctype[1].downcase == 'klanfr'
      Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif doctype[1].downcase == 'mds senat'
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
  end

  def self.extract_title(tr)
    tr.element_children[2].text.match(/(.+)\s+(?:Urheber|PlPr)/m)[1].gsub(/\n/, ' ').strip
  end

  def self.extract_url(tr)
    path = tr.element_children[3].element_children[2]['href']
    Addressable::URI.parse(BASE_URL).join(path).normalize.to_s
  end

  def self.extract_paper(tr)
    title = extract_title(tr)
    full_reference = extract_full_reference(tr)
    url = extract_url(tr)
    legislative_term, reference = extract_reference(full_reference)

    doctype = extract_doctype(tr)
    fail "[HB #{full_reference}] doctype unknown for Paper" if doctype.nil?

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title,
      url: url,
      is_answer: true,
      answerers: { ministries: ['Senat'] }
    }
  end

  def self.extract_meta_rows(element)
    data = []
    first = true
    element.search('br').each do |br|
      frag = Nokogiri::HTML.fragment('')
      el = br
      if first
        first = false
        f = Nokogiri::HTML.fragment('')
        f << el.previous.clone
        data << f
      end
      loop do
        el = el.next
        break if el.nil? || el.try(:name) == 'br'
        frag << el.clone
      end
      data << frag
    end
    data
  end

  def self.extract_paper_detail(mp)
    detail_body = mp.search('//table/tr/td[contains(@class, "tdtext")]').last
    published_at = nil
    origniators = nil
    extract_meta_rows(detail_body).each do |row|
      if row.text.include?('KlAnfr') || row.text.include?('GrAnfr')
        origniators = row.text.match(/.+Urheber:(?<org>.+)/)
      end
      if row.text.include?('KlAnfr')
        published_at = row.text.match(/.+?\s([\d\.]+)/)
      end
      if row.text.include?('MdS Senat (Antwort)')
        published_at = row.text.match(/.+\s+([\d\.]+)/)
      end
    end
    return nil if origniators.nil? || published_at.nil?
    {
      published_at: Date.parse(published_at[1].strip),
      originators: { people: [], parties: origniators[1].split(',').map(&:strip) }
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/index.php?id=507'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      papers = []
      m = mechanize
      # to initialize session
      m.get BASE_URL
      # search form
      mp = submit_search(m)
      body = mp.search("//table[@id='suchergebnisse']")
      fail "HB [#{full_reference}]: result page missing" if body.nil?
      results = BremenBuergerschaftScraper.extract_results(body)
      results.each do |table_row|
        begin
          paper = BremenBuergerschaftScraper.extract_paper(table_row)
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

    def submit_search(m)
      mp = m.get SEARCH_URL
      form = mp.form 'theForm'
      fail 'HB: search form missing' if form.nil?

      fail 'HB: legislative_term missing' if !form.field_with(name: 'lp').options.any? { |opt| opt.value == @legislative_term.to_s }
      form.field_with(name: 'lp').value = @legislative_term
      form.field_with(name: 'vorlageart').value = TYPES
      submit_button = form.submits.find { |btn| btn.value == 'suchen' }
      mp = m.submit(form, submit_button)
      mp
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/index.php?id=507'

    def scrape
      m = mechanize
      # get a session
      m.get BASE_URL
      mp = m.get SEARCH_URL
      form = mp.form 'theForm'
      fail "HB [#{full_reference}]: search form missing" if form.nil?

      fail 'HB: legislative_term missing' if !form.field_with(name: 'lp').options.any? { |opt| opt.value == @legislative_term.to_s }
      form.field_with(name: 'lp').value = @legislative_term
      form.field_with(name: 'vorlageart').value = TYPES
      form.field_with(name: 'drucksachennr').value = @reference
      submit_button = form.submits.find { |btn| btn.value == 'suchen' }
      mp = m.submit(form, submit_button)

      body = mp.search("//table[@id='suchergebnisse']")
      fail "HB [#{full_reference}]: result page missing" if body.nil?
      paper = BremenBuergerschaftScraper.extract_paper(body.at_css('tr'))

      process_url = body.at_css('tr').element_children[3].at_css('a').attributes['href'].value
      fail "HB [#{full_reference}]: no button for details found" if process_url.nil?

      mp = m.get Addressable::URI.parse(BASE_URL).join(process_url).normalize.to_s

      complete_paper = BremenBuergerschaftScraper.extract_paper_detail(mp)
      fail "HB [#{full_reference}]: no details found" if complete_paper.nil?

      paper.merge complete_paper
    end
  end
end