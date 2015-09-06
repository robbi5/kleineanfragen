require 'date'

module HamburgBuergerschaftScraper
  BASE_URL = 'https://www.buergerschaft-hh.de/ParlDok'
  TYPES = ['Schriftliche Kleine Anfrage', 'Große Anfrage']
  # because hamburg has a limit of displayed documents, we need to split the date range search
  # when scraping fails because of too much documents, increment this number, should not happen too often
  SEARCH_PARTS = 4

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
        body.css('.title').each do |title_el|
          begin
            paper = HamburgBuergerschaftScraper.extract(title_el)
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
      form = mp.forms.last
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

  def self.extract(title_el)
    next_row = title_el.parent.next_element
    title_text = title_el.text.strip
    full_reference = next_row.element_children[0].text.strip
    reference = full_reference.split('/').last
    legislative_term = full_reference.split('/').first
    date = Date.parse(next_row.element_children[2].text.strip)
    path = title_el.element_children[0]['href']
    url = Addressable::URI.parse(BASE_URL).join(path).normalize.to_s

    if url.starts_with? 'javascript:'
      fail "Paper [HH #{full_reference}] is non-public"
    end

    doctype_el = next_row.element_children[1]
    if doctype_el.text.scan(/kleine/i).present?
      doctype = Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif doctype_el.text.scan(/große/i).present?
      doctype = Paper::DOCTYPE_MAJOR_INTERPELLATION
    else
      fail "doctype unknown for Paper [HH #{full_reference}]"
    end

    originators = next_row.next_element.element_children[1].text.strip
    originators = NamePartyExtractor.new(originators).extract
    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title_text,
      url: url,
      published_at: date,
      originators: originators,
      # hamburg exposes no answerers
      answerers: { ministries: ['Senat'] }
    }
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/dokumentennummer'

    def scrape
      m = mechanize
      # get a session
      m.get BASE_URL
      mp = m.get SEARCH_URL
      form = mp.forms.last
      form.field_with(name: 'LegislaturPeriodenNummer').value = @legislative_term
      form.field_with(name: 'DokumentenNummer').value = @reference
      submit_button = form.submits.find { |btn| btn.value == 'Suchen' }
      mp = m.submit(form, submit_button)
      body = mp.search("//table[@id='parldokresult']")
      HamburgBuergerschaftScraper.extract(body.at_css('.title'))
    end
  end
end