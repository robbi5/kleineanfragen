module RheinlandPfalzLandtagScraper
  BASE_URL = 'http://opal.rlp.de'

  def self.extract_records(page)
    page.search('//tbody[@name="RecordRepeater"]')
  end

  def self.extract_detail_block(page)
    page.search('./tr[@name="Repeat_Fund"]/td[3]').first ||
    page.search('./tr[@name="Repeat_D_Fund"]/td[3]').first
  end

  def self.extract_title(block)
    block.search('./tr[@name="Repeat_WHET"]/td[2]').first.try(:text) ||
    block.search('./tr[@name="Repeat_D_WHET"]/td[2]').first.try(:text)
  end

  def self.extract_link(container)
    container.at_css('a')
  end

  def self.extract_full_reference(link)
    link.text.strip
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_url(link)
    link.attributes['href'].value
  end

  def self.extract_ministries(ministry_line)
    ministry_line.split(/Ministerium/)
      .reject(&:empty?)
      .map { |s| s.strip.gsub(/\s*,$/, '').sub(/^Ministerium\s+/, '') }
      .map { |s| s != 'Staatskanzlei' ? "Ministerium #{s}" : s }
      .uniq
  end

  # metadata is one big td, lines are seperated by <br>
  # split it at the <br>s, so we get an array of lines again
  def self.extract_meta_rows(element)
    data = []
    element.search('br').each do |br|
      frag = Nokogiri::HTML.fragment('')
      el = br
      loop do
        el = el.next
        break if el.nil? || el.try(:name) == 'br'
        frag << el.clone
      end
      data << frag
    end
    data
  end

  def self.extract_link(meta_rows)
    answer_row = meta_rows.find { |row| row.text.include?('Antwort') && !row.text.include?('Ergänzung') }
    return nil if answer_row.nil?
    answer_row.search('a').find { |el| el.text.include?('/') }
  end

  def self.extract_doctype(meta_row)
    differentiation = meta_row.text.downcase.match(/(kleine|große)\s+anfrage/m)
    if differentiation[1] == 'kleine'
      return Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif differentiation[1] == 'große'
      return Paper::DOCTYPE_MAJOR_INTERPELLATION
    else
      return nil
    end
  end

  def self.extract_meta_multiline(meta_rows)
    o_results = a_results = nil
    meta_rows.each do |line|
      # Kleine Anfrage Matthias Lammert (CDU) 14.06.2016 Drucksache 17/106 (1 S.)
      match = line.text.match(/(?:Kleine|Große)\s+Anfrage\s+(.+?)\s+(?:\d+\.[\d\.]+)/)
      o_results = match if match && !line.text.include?('Antwort')
      # Antwort zu Drs 17/106 Matthias Lammert (CDU), Ministerium der Finanzen 04.07.2016 Drucksache 17/324
      # Antwort  Ministerium für Integration, Familie, Kinder, Jugend und Frauen 20.03.2015 Drucksache   16/4788  (27 S.)
      match = line.text.match(/Antwort(?:\s+zu\s+Drs\.?\s+[\d\/]+)?\s+(.+?)\s+(\d+\.[\d\.]+)/m)
      a_results = match if match && !line.text.include?('Ergänzung')
    end
    return {} if o_results.nil? || a_results.nil?

    org = o_results[1].split(',').map(&:strip)
    ans = a_results[1].split(',').map(&:strip)

    answerers = (ans - org).join(', ')

    {
      originators: o_results[1].strip,
      answerers: answerers,
      published_at: a_results[2],
    }
  end

  def self.extract_meta(meta_row)
    doctype = extract_doctype(meta_row)
    return nil if doctype.nil?

    meta_rows = extract_meta_rows(meta_row)
    link = extract_link(meta_rows)

    if doctype == Paper::DOCTYPE_MINOR_INTERPELLATION
      results = meta_row.text.match(/Kleine\s+Anfrage\s+[\d\s]+(.+?)\s+und\s+Antwort\s+(.+?)\s+([\d\.]+)\s+/)
      if !results.nil?
        return {
          doctype: doctype,
          originators: results[1].strip,
          answerers: results[2].strip,
          published_at: results[3],
          link: link
        }
      end
    end

    meta = extract_meta_multiline(meta_rows)
    {
      doctype: doctype,
      link: link
    }.merge(meta)
  end

  def self.extract_paper(item, check_pdf: true)
    title = extract_title(item)
    meta_row = extract_detail_block(item)

    # for broken records like 16D4556
    fail "RP [?]: no meta information found. Paper title: #{title}" if meta_row.nil?

    meta = extract_meta(meta_row)
    fail "RP [?]: no readable meta information found. Paper title: #{title}" if meta.nil?
    fail "RP [?]: key meta information missing. Paper title: #{title}" if meta[:doctype].nil? || meta[:link].nil? || meta[:published_at].nil?

    doctype = meta[:doctype]
    full_reference = extract_full_reference(meta[:link])
    url = extract_url(meta[:link])
    legislative_term, reference = extract_reference(full_reference)

    # not all papers are available
    if check_pdf
      begin
        resp = Scraper.patron_session.head(url)
      rescue => e
        raise "RP [#{full_reference}]: url throwed #{e}"
      end
      if resp.status == 404 || resp.url.include?('error404.html')
        fail "RP [#{full_reference}]: url throws 404"
      end
    end

    ministries = []
    if doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
      originators = { people: [], parties: meta[:originators].split(',').map(&:strip) }
    else
      originators = NamePartyExtractor.new(meta[:originators]).extract
    end
    ministries = extract_ministries(meta[:answerers]) unless meta[:answerers].nil?
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

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKU.web'
    TYPE = 'KLEINE ANFRAGE UND ANTWORT; ANTWORT'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      mp = m.get SEARCH_URL
      search_form = mp.form '__form'
      fail 'search form missing' if search_form.nil?

      # fill search form
      search_form.field_with(name: '__action').value = 20
      search_form.field_with(name: '02_PDOKU_WP').value = @legislative_term
      search_form.field_with(name: '03_PDOKU_DART').value = 'D'
      search_form.field_with(name: '05_PDOKU_DTYP').value = TYPE
      mp = m.submit(search_form)

      # retrieve new search form with more options
      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 21
      search_form.field_with(name: 'LimitMaximumHitCount').options.find { |opt| opt.text.include? 'alle' }.select

      # Fail if no hits
      fail 'search returns no results' if mp.search('//span[@name="HitCountZero"]').size > 0

      mp = m.submit(search_form)

      # switch display variant
      type_form = mp.form '__form'
      type_form.field_with(name: '__action').value = 52
      type_form.field_with(name: 'PDOKU_Browse_ReportFormatList').value = 'PDOKU_Vorgaenge_Report'

      mp = m.submit(type_form)

      papers = []
      loop do
        RheinlandPfalzLandtagScraper.extract_records(mp).each do |item|
          begin
            paper = RheinlandPfalzLandtagScraper.extract_paper(item)
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

        # submit form for next page
        break if mp.search('//a[@name="NextRecords"]').size == 0
        search_form = mp.form '__form'
        search_form.field_with(name: '__action').value = 49
        mp = m.submit(search_form)
      end
      papers unless streaming
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink&format=PDOKU_Vollanzeige_Report&search='

    def scrape
      mp = mechanize.get self.class.build_search_url(@legislative_term, @reference)
      item = RheinlandPfalzLandtagScraper.extract_records(mp).first
      RheinlandPfalzLandtagScraper.extract_paper(item)
    end

    def self.build_search_url(legislative_term, reference)
      SEARCH_URL + CGI.escape("WP=#{legislative_term} AND DART=D AND DNR,KORD=#{reference}")
    end
  end
end