require 'date'

module BundestagScraper
  BASE_URL = 'http://dipbt.bundestag.de'
  OVERVIEW_URL = BASE_URL + '/extrakt/ba'

  class Overview < Scraper
    TYPES = ['Kleine Anfrage', 'Große Anfrage']

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      mp = m.get "#{OVERVIEW_URL}/WP#{@legislative_term}/"
      table = mp.search "//table[contains(@summary, 'Beratungsabläufe')]"

      papers = []
      table.css('tbody tr').each do |row|
        type = row.css('td')[0].text
        link = row.at_css('td a')
        detail_url = link.attributes['href'].value

        next unless TYPES.include?(type)

        begin
          detail_url = "#{OVERVIEW_URL}/WP#{@legislative_term}/#{detail_url}"
          detail_page = m.get detail_url
          paper = BundestagScraper.scrape_vorgang(detail_page, detail_url)
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
    START_URL = BASE_URL + '/dip21.web/bt'
    SEARCH_URL = BASE_URL + '/dip21.web/searchDocuments.do'

    def scrape
      m = mechanize
      # need to open start page first, it sets some required session cookies
      m.get START_URL
      # then we can access the search
      mp = m.get SEARCH_URL

      search_form = mp.forms[0]
      search_form.radiobutton_with(name: 'dokType', value: 'drs').check
      search_form.field_with(name: 'wahlperiode').options.find { |opt| opt.text.strip == @legislative_term.to_s }.select
      search_form['nummer'] = full_reference
      submit_button = search_form.submits.find { |btn| btn.value == 'Suchen' }
      page = m.submit(search_form, submit_button).root

      vorgaenge_link = page.at_css('.contentBox .tabReiter a')
      page = m.click(vorgaenge_link).root

      id = page.at_css('.dtBreit + .adjustRight b').text
      _, id = id.match(/\d+-(\d+)/).to_a
      folder = id[0...-2]

      detail_url = "#{OVERVIEW_URL}/WP#{@legislative_term}/#{folder}/#{id}.html"
      detail_page = m.get detail_url

      BundestagScraper.scrape_vorgang(detail_page, detail_url)
    end
  end

  def self.scrape_vorgang(page, detail_url)
    content = page.content
    scrape_content(content, detail_url)
  end

  def self.scrape_content(content, detail_url)
    doc = extract_doc(content)

    doctype = extract_doctype(doc)
    fail "#{detail_url}: doctype unknown: #{doctype}" if doctype.blank?

    status = extract_status(doc)
    fail "#{detail_url}: ignored, status: #{status}" unless status == 'Beantwortet'

    title = extract_title(doc)
    legislative_term = doc.at_css('VORGANG WAHLPERIODE').text.to_i

    url = nil
    full_reference = ''
    found = false
    doc.css('WICHTIGE_DRUCKSACHE').each do |node|
      next unless node.at_css('DRS_TYP').text == 'Antwort'
      found = true
      url = node.at_css('DRS_LINK').try(:text)
      full_reference = node.at_css('DRS_NUMMER').text
    end
    fail "#{detail_url}: ignored, no paper found" unless found && !url.blank?

    reference = full_reference.split('/').last
    normalized_url = Addressable::URI.parse(url).normalize.to_s
    ado = extract_answerers_date_and_originators(doc)
    fail "#{full_reference}: no date found" if ado[:date].nil?
    published_at = Date.parse(ado[:date])

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title,
      url: normalized_url,
      published_at: published_at,
      originators: ado[:originators],
      is_answer: true,
      answerers: ado[:answerers],
      source_url: detail_url
    }
  end

  def self.extract_answerers_date_and_originators(doc)
    originators = { people: [], parties: [] }
    answerers = { ministries: [] }
    date = nil
    doc.css('VORGANGSABLAUF VORGANGSPOSITION').each do |node|
      urheber = node.at_css('URHEBER').text
      # originator entry should always have a 'PERSOENLICHER_URHEBER'
      is_ministry = node.at_css('PERSOENLICHER_URHEBER').nil?
      if is_ministry
        _, ministry = urheber.match(/.*,(?:\s+Urheber :)?\s+([^(]*)/).to_a
        unless ministry.nil?
          ministry = ministry.strip.sub(/^Bundesregierung, /, '')
          answerers[:ministries] << ministry
        end
        fundstelle = node.at_css('FUNDSTELLE').text
        _, date = fundstelle.match(/(\d+\.\d+\.\d+)\s/).to_a
      else
        node.css('PERSOENLICHER_URHEBER').each do |unode|
          originators[:people] << [
            unode.at_css('PERSON_TITEL').try(:text),
            unode.at_css('VORNAME').text,
            unode.at_css('NAMENSZUSATZ').try(:text),
            unode.at_css('NACHNAME').text
          ].reject(&:blank?).map(&:strip).join(' ')
          party = unode.at_css('FRAKTION').text
          originators[:parties] << party unless originators[:parties].include? party
        end
      end
    end
    { answerers: answerers, date: date, originators: originators }
  end

  def self.extract_title(doc)
    doc.at_css('VORGANG TITEL').text.strip
  end

  def self.extract_status(doc)
    doc.at_css('VORGANG AKTUELLER_STAND').text
  end

  def self.extract_doctype(doc)
    type = extract_type(doc)
    case type
    when 'Kleine Anfrage'
      Paper::DOCTYPE_MINOR_INTERPELLATION
    when 'Große Anfrage'
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
  end

  def self.extract_doc(content)
    comment_start = content.index '<?xml'
    comment_end = content.index('-->', comment_start)
    xml = content[comment_start...comment_end]
    xml = xml.strip.gsub(/<-.*->/, '') # remove nested "comments"
    Nokogiri.parse xml
  end

  def self.extract_type(doc)
    doc.at_css('VORGANG VORGANGSTYP').text
  end
end