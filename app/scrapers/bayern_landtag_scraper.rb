require 'date'

module BayernLandtagScraper
  BASE_URL = 'http://www1.bayern.landtag.de'

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/webangebot1/dokumente.suche.maske.jsp?DOKUMENT_TYPE=EXTENDED&STATE=SHOW_MASK'

    def supports_pagination?
      true
    end

    def supports_streaming?
      true
    end

    def scrape(&block)
      page = 1
      papers = []
      block = -> (paper) { papers << paper } unless block_given?
      loop do
        mp = search(page)
        logger.debug "[scrape] page: #{page}"
        scrape_page(mp, &block)
        break unless mp.search('//div[contains(@class, "cbox_content")]//a[contains(text(), "nächste Treffer")]').size > 0
        page += 1
      end
      papers unless block_given?
    end

    def scrape_paginated(page, &block)
      papers = []
      block = -> (paper) { papers << paper } unless block_given?
      mp = search(page)
      logger.debug "[scrape_paginated] page: #{page}"
      scrape_page(mp, &block)
      papers unless block_given?
    end

    def scrape_page(mechanize_page)
      streaming = block_given?
      papers = []
      BayernLandtagScraper.extract_first_rows(mechanize_page).each do |row|
        begin
          paper = BayernLandtagScraper.extract_paper(row)
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

    def search(page)
      @m ||= mechanize
      mp = @m.get SEARCH_URL
      search_form = mp.form 'suche'
      search_form.field_with(name: 'DOKUMENT_INTEGER_WAHLPERIODE').value = @legislative_term
      search_form.field_with(name: 'DOKUMENT_VORGANGSART').options.find { |opt| opt.text.include? 'Schriftliche Anfrage' }.select
      search_form.field_with(name: 'DOKUMENT_INTEGER_TREFFERANZAHL').value = @per_page
      search_form.add_field!('DOKUMENT_INTEGER_RESULT_START_INDEX', @per_page * (page - 1)) if page > 1
      submit_button = search_form.submits.find { |btn| btn.value == 'Suche starten' }
      @m.submit(search_form, submit_button)
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/webangebot1/dokumente.suche.maske.jsp?STATE=SHOW_MASK&BUTTONSCHLAGWORT=Suche+starten&DOKUMENT_DOKUMENTNR='

    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape(full_reference)
      mp = mp.link_with(href: /\#LASTFOLDER$/).click
      first_row = BayernLandtagScraper.extract_first_rows(mp).first
      BayernLandtagScraper.extract_paper(first_row)
    end
  end

  def self.extract_first_rows(page)
    page.search('//table[not(contains(@class, "marg_"))]//tr[not(contains(@class, "clr_listhead"))]/td/b').map do |item|
      item.parent.parent
    end
  end

  def self.extract_meta(first_row)
    text = first_row.at_css('b').try(:text)
    return nil if text.nil?
    {
      full_reference: text.match(/Nr. ([\d\/]+)/)[1],
      published_at: text.match(/([\d\.]+)$/)[1]
    }
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_link(first_row)
    first_row.css('a').last
  end

  def self.extract_url(link)
    rel_url = link.attributes['href'].value
    return nil if rel_url.nil?
    Addressable::URI.parse(BASE_URL).join(rel_url).normalize.to_s
  end

  def self.extract_party(fourth_row)
    fourth_row.search('.//table//tr[1]/td[2]').first.try(:text).try(:strip)
  end

  def self.extract_title(third_row)
    title_el = third_row.search('./td[3]').first
    return nil if title_el.nil?
    title_el.children.first.text.gsub(/\s+/, ' ').strip.gsub(/\n/, '-').gsub('... [mehr]', '').gsub('[weniger]', '').strip
  end

  def self.extract_paper(first_row)
    begin
      second_row = first_row.next_element
      third_row = second_row.next_element
    rescue
      raise '[?] needed html structure is not there'
    end

    # look for detail row
    begin
      fourth_row = third_row.next_element
      detail = !fourth_row.try(:at_css, 'table').nil?
    rescue
      detail = false
    end

    meta = extract_meta(first_row)
    fail "[#{full_reference}] meta element not found" if meta.nil?

    full_reference = meta[:full_reference]
    legislative_term, reference = extract_reference(full_reference)
    published_at = Date.parse(meta[:published_at])

    link = extract_link(first_row)
    fail "[#{full_reference}] link element not found" if link.nil?

    url = extract_url(link)
    title = extract_title(third_row)
    fail "[#{full_reference}] title element not found" if title.nil?

    party = extract_party(fourth_row) if detail

    paper = {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
      title: title,
      url: url,
      published_at: published_at,
      is_answer: true
      # originators only on detail page
      # answerers not available
    }
    paper[:originators] = { parties: [party] } if detail
    paper
  end
end