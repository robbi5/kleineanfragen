require 'date'

module ThueringenLandtagScraper
  BASE_URL = 'http://www.parldok.thueringen.de/ParlDok'
  TYPES = ['Antwort auf Große Anfrage', 'Antwort auf Kleine Anfrage']

  def self.extract_results(page)
    page.css('.title')
  end

  def self.extract_next_row(title_el)
    title_el.parent.next_element
  end

  def self.extract_title_text(title_el)
    title_el.text.strip
  end

  def self.extract_full_reference(next_row)
    next_row.element_children[0].text.strip
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_path(title_el)
    title_el.element_children[0]['href']
  end

  def self.extract_url(path)
    Addressable::URI.parse(BASE_URL).join(path).normalize.to_s
  end

  def self.extract_doctype_el(next_row)
    next_row.element_children[1]
  end

  def self.extract_meta(next_row)
    date = next_row.element_children[2].text.strip

    doctype_el = extract_doctype_el(next_row)
    if doctype_el.text.scan(/kleine/i).present?
      doctype = Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif doctype_el.text.scan(/große/i).present?
      doctype = Paper::DOCTYPE_MAJOR_INTERPELLATION
    else
      fail "doctype unknown for Paper [TH #{full_reference}]"
    end

    answerers = next_row.next_element.element_children[1].text.strip.match(/([^\(]+)/)

    {
      doctype: doctype,
      published_at: date,
      answerers: answerers.try(:[], 1)
    }
  end

  def self.extract_originators(text)
    doc_originators = text.match(/(Kleine|Große)\s+Anfrage\s+(.+)/)

    if doc_originators[1].downcase == 'große'
      originators = { people: [], parties: [doc_originators[2].strip] }
    else
      originators = NamePartyExtractor.new(doc_originators[2].strip).extract
    end

    {
      originators: originators
    }
  end

  def self.extract_paper(title_el)
    next_row = extract_next_row(title_el)
    title_text = extract_title_text(title_el)
    full_reference = extract_full_reference(next_row)
    legislative_term, reference = extract_reference(full_reference)
    path = extract_path(title_el)
    url = extract_url(path)
    meta = extract_meta(next_row)

    doctype = meta[:doctype]
    date = Date.parse(meta[:published_at])
    ministries = []
    ministries = [meta[:answerers].strip] unless meta[:answerers].nil?
    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title_text,
      url: url,
      published_at: date,
      # originators are coming from detail scraper
      answerers: { ministries: ministries }
    }
  end

  def self.extract_paper_detail(mp)
    pbody = mp.search('//table[contains(@class, "element-process")]')
    ThueringenLandtagScraper.extract_originators(pbody.at_css('.element-vorgang a').previous.text)
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/formalkriterien'

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
      loop do
        body = mp.search("//table[@id='parldokresult']")
        results = ThueringenLandtagScraper.extract_results(body)
        results.each do |title_el|
          begin
            paper = ThueringenLandtagScraper.extract_paper(title_el)
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
        next_page = next_page_el(mp)
        break if next_page.nil?
        mp = m.click next_page
      end
      papers unless streaming
    end

    def next_page_el(mp)
      # if there is no next page, a">>" becomes text ">>"
      mp.search("//a[text()[normalize-space(.)='>>']]").first
    end

    def submit_search(m)
      mp = m.get SEARCH_URL
      form = mp.forms.second
      form.field_with(name: 'LegislaturperiodenNummer').value = @legislative_term
      form.field_with(name: 'DokumententypId').options.each do |opt|
        if TYPES.include? opt.text.strip
          opt.select
        else
          opt.unselect
        end
      end
      submit_button = form.submits.find { |btn| btn.value == 'Suchen' }
      mp = m.submit(form, submit_button)
      mp
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/dokumentennummer'

    def scrape
      m = mechanize
      # get a session
      m.get BASE_URL
      mp = m.get SEARCH_URL
      form = mp.forms.second
      form.field_with(name: 'LegislaturPeriodenNummer').value = @legislative_term
      form.field_with(name: 'DokumentenNummer').value = @reference
      submit_button = form.submits.find { |btn| btn.value == 'Suchen' }
      mp = m.submit(form, submit_button)

      body = mp.search("//table[@id='parldokresult']")
      paper = ThueringenLandtagScraper.extract_paper(body.at_css('.title'))

      button = body.at_css('.parldokresult-vorgang').attributes['onclick'].value

      fail "TH [#{full_reference}]: no button to show details found" if button.nil?

      detail_url = button.match(/location.href='(.+)'/)
      mp = m.get Addressable::URI.parse(BASE_URL).join(detail_url[1]).normalize.to_s

      complete_paper = ThueringenLandtagScraper.extract_paper_detail(mp)
      paper.merge complete_paper
    end
  end
end