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
          paper = BundestagScraper.scrape_vorgang(m, "#{OVERVIEW_URL}/WP#{@legislative_term}/#{detail_url}")
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

      BundestagScraper.scrape_vorgang(m, "#{OVERVIEW_URL}/WP#{@legislative_term}/#{folder}/#{id}.html")
    end
  end

  def self.scrape_vorgang(mechanize, detail_url)
    page = mechanize.get detail_url
    comment_start = page.content.index '<?xml'
    comment_end = page.content.index('-->', comment_start)
    xml = page.content[comment_start...comment_end]
    xml = xml.strip.gsub(/<-.*->/, '') # remove nested "comments"

    doc = Nokogiri.parse xml
    type = doc.at_css('VORGANG VORGANGSTYP').text
    status = doc.at_css('VORGANG AKTUELLER_STAND').text
    fail "#{detail_url}: ignored, status: #{status}" unless status == 'Beantwortet'

    doctype = case type
              when 'Kleine Anfrage'
                Paper::DOCTYPE_MINOR_INTERPELLATION
              when 'Große Anfrage'
                Paper::DOCTYPE_MAJOR_INTERPELLATION
              end
    fail "#{detail_url}: doctype unknown: #{type}" if doctype.blank?

    title = doc.at_css('VORGANG TITEL').text.strip
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
    date = nil

    originators = { people: [], parties: [] }
    answerers = { ministries: [] }
    doc.css('VORGANGSABLAUF VORGANGSPOSITION').each do |node|
      urheber = node.at_css('URHEBER').text
      if urheber.starts_with?('Antwort') || node.at_css('FUNDSTELLE_LINK').try(:text) == url
        _, ministry = urheber.match(/Antwort,(?:\s+Urheber :)?\s+([^(]*)/).to_a
        unless ministry.nil?
          ministry = ministry.strip.sub(/^Bundesregierung, /, '')
          answerers[:ministries] << ministry
        end
        fundstelle = node.at_css('FUNDSTELLE').text
        _, date = fundstelle.match(/(\d+\.\d+\.\d+)\s/).to_a
      elsif urheber.starts_with? 'Kleine Anfrage'
        node.css('PERSOENLICHER_URHEBER').each do |unode|
          originators[:people] << [
            unode.at_css('PERSON_TITEL').try(:text),
            unode.at_css('VORNAME').text,
            unode.at_css('NAMENSZUSATZ').try(:text),
            unode.at_css('NACHNAME').text
          ].reject(&:blank?).join(' ')
          party = unode.at_css('FRAKTION').text
          originators[:parties] << party unless originators[:parties].include? party
        end
      end
    end

    fail "#{full_reference}: no date found" if date.nil?
    published_at = Date.parse(date)

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title,
      url: normalized_url,
      published_at: published_at,
      originators: originators,
      is_answer: true,
      answerers: answerers
    }
  end
end