require 'date'

module SachsenAnhaltLandtagScraper
  BASE_URL = 'http://padoka.landtag.sachsen-anhalt.de'
  SEARCH_URL = BASE_URL + '/starweb/PADOKA/servlet.starweb?path=PADOKA/LISSH.web&AdvancedSuche=yes'

  def self.extract_blocks(mp)
    mp.search('//div[@id="PrintContainer"]//li[@name="RecordRepeater"]')
  end

  def self.extract_detail_block(mp)
    mp.search('//div[@id="article"]').first
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  # examples:
  # Bezug: Kleine Anfrage und Antwort Hardy Peter Güssau (CDU), Frank Scheurell (CDU) und Antwort Ministerium für Landesentwicklung und Verkehr 04.06.2014 Drucksache 6/3163 (KA 6/8343) (2 S.)
  # Bezug: Kleine Anfrage und Antwort Eva Feußner (CDU) und Antwort Ministerium für Wissenschaft und Wirtschaft 24.07.2014 Drucksache 6/3311 (KA 6/8388) (3 S.)
  # Bezug: Kleine Anfrage und Antwort (Unterrichtung) Ministerium für Arbeit und Soziales, Landesregierung 05.05.2011 Drucksache 6/41 (KA 5/7302) (9 S.)
  # Bezug: Antwort Landesregierung 09.02.2015 Drucksache 6/3801 (79 S.)
  # Große Anfrage SPD 07.11.2014 Drucksache 6/3591 (9 S.)
  def self.extract_meta(line)
    is_answer = nil
    if line.match(/Kleine\s+Anfrage/)
      doctype = Paper::DOCTYPE_MINOR_INTERPELLATION
      match = line.match(/Kleine\s+Anfrage\s+und\s+Antwort\s+(.+)\s+([\d\.]+)\s+Drucksache\s+([\d\/]+)/m)
      return nil if match.nil?
      # FIXME: this is broken for DetailScraper, answerer is not seperated by "und Antwort"
      originators_and_answerers = match[1].strip.match(/(.+)\s+und\s+Antwort\s+(.+)/)
      is_answer = true unless originators_and_answerers.nil?
      originators_and_answerers = [nil, nil, nil] if originators_and_answerers.nil?
    elsif line.match(/Große\s+Anfrage/)
      doctype = Paper::DOCTYPE_MAJOR_INTERPELLATION
      match = line.match(/Große\s+Anfrage\s+(.+)\s+([\d\.]+)\s+Drucksache\s+([\d\/]+)/m)
      originators_and_answerers = [nil, match[1].strip, nil]
      is_answer = false
    elsif line.match(/^(?:Bezug:\s+)?Antwort\s+/)
      doctype = Paper::DOCTYPE_MAJOR_INTERPELLATION
      match = line.match(/Antwort\s+(.+)\s+([\d\.]+)\s+Drucksache\s+([\d\/]+)/)
      originators_and_answerers = [nil, nil, match[1].strip]
      is_answer = true
    else
      return nil
    end

    {
      full_reference: match[3].strip,
      doctype: doctype,
      originators: originators_and_answerers[1].try(:strip),
      answerers: originators_and_answerers[2].try(:strip),
      published_at: match[2].strip,
      is_answer: is_answer
    }
  end

  def self.extract_paper(item)
    title = item.at_css('h1').try(:text)
    fail 'ST [?]: no title element found' if title.nil?

    meta_line = item.at_css('.info').try(:text)
    fail "ST [?]: no meta line found Paper title: #{title}" if meta_line.nil?

    return nil if meta_line.include?('Bezug: Plenarprotokoll')

    link = item.at_css('a.download')
    fail "ST [?]: no link element found. Paper title: #{title}" if link.nil?

    url = link.attributes['href'].value

    meta = extract_meta(meta_line)
    fail "ST [?]: no matching meta line found. Paper title: #{title}" if meta.nil?

    doctype = meta[:doctype]
    full_reference = meta[:full_reference]
    legislative_term, reference = extract_reference(full_reference)

    originators = meta[:originators]
    originators = NamePartyExtractor.new(originators).extract unless originators.nil?

    ministries = nil
    ministries = meta[:answerers].split(',').map(&:strip) unless meta[:answerers].nil?

    published_at = Date.parse(meta[:published_at])

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title,
      url: url,
      published_at: published_at,
      originators: originators,
      is_answer: meta[:is_answer],
      answerers: { ministries: ministries },
      source_url: Detail.build_search_url(legislative_term, reference)
    }
  end

  class Overview < Scraper
    TYPES = 'KLEINE ANFRAGE UND ANTWORT; ANTWORT'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      mp = m.get SEARCH_URL
      search_form = mp.form '__form'

      # fill search form
      search_form.field_with(name: '__action').value = 26
      search_form.field_with(name: '02_LISSH_WP').value = @legislative_term
      search_form.field_with(name: '05_LISSH_DTYP').value = TYPES
      mp = m.submit(search_form)

      # Fail if no hits
      fail 'search: no results' if mp.search('//div[contains(@class,"contents")]//div[@id="header"]').try(:first).try(:text).try(:include?, 'keine Treffer')

      # switch to print view
      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 67
      mp = m.submit(search_form)

      papers = []

      SachsenAnhaltLandtagScraper.extract_blocks(mp).each do |item|
        begin
          paper = SachsenAnhaltLandtagScraper.extract_paper(item)
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

  def self.extract_detail_paper(item)
    title = item.at_css('h1').try(:text)
    fail 'ST [?]: no title element found' if title.nil?

    meta_lines = item.css('.report-list--wrapper')
    fail 'ST [?]: no meta lines found Paper title: #{title}' if meta_lines.nil?

    link, meta, last_meta = nil, nil, nil
    meta_lines.each do |line|
      line_meta = extract_meta(line.at_css('.report-list--content').try(:text))
      next if line_meta.nil?
      if line_meta[:is_answer]
        line_meta[:originators] = last_meta[:originators] unless last_meta.nil?
        meta = line_meta
        link = line.at_css('a.download')
      end
      last_meta = line_meta
    end

    fail "ST [?]: no matching meta line found Paper title: #{title}" if meta.nil?
    fail "ST [?]: no link element found. Paper title: #{title}" if link.nil?

    url = link.attributes['href'].value
    doctype = meta[:doctype]
    full_reference = meta[:full_reference]
    legislative_term, reference = extract_reference(full_reference)

    originators = meta[:originators]
    unless originators.nil?
      originators = NamePartyExtractor.new(originators).extract if doctype == Paper::DOCTYPE_MINOR_INTERPELLATION
      originators = { people: [], parties: [originators] } if doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
    end

    ministries = nil
    ministries = meta[:answerers].split(',').map(&:strip) unless meta[:answerers].nil?

    published_at = Date.parse(meta[:published_at])

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

  class Detail < DetailScraper
    def scrape
      m = mechanize
      mp = m.get(self.class.build_search_url(@legislative_term, @reference))

      # submit hidden redirection form
      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 37
      mp = m.submit(search_form)

      # Fail if no hits
      fail "ST [#{full_reference}]: search returns no results" if mp.search('//div[@name="NoReportGenerated"]/*').size > 0

      # switch to full view
      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 65
      search_form.field_with(name: 'LISSH_Browse_ReportFormatList').value = 'LISSH_Vorgaenge_Report'
      mp = m.submit(search_form)

      item = SachsenAnhaltLandtagScraper.extract_detail_block(mp)
      SachsenAnhaltLandtagScraper.extract_detail_paper(item)
    end

    def self.build_search_url(legislative_term, reference)
      BASE_URL + '/starweb/PADOKA/servlet.starweb?path=PADOKA/LISSH.web&DokumentSuche=yes' +
        "&01_LISSH_DOK_DART=(D\\KA)&02_LISSH_DOK_WP=#{legislative_term}&03_LISSH_DOK_DNR=#{reference}"
    end
  end
end