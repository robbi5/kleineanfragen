require 'date'

module BremenBuergerschaftScraper
  BASE_URL = 'https://paris.bremische-buergerschaft.de'
  SEARCH_URL = BASE_URL + '/starweb/paris/servlet.starweb?path=paris/LISSH.web'
  TYPES = [
    'KLEINE ANFRAGE UND ANTWORT DES SENATS',
    'MITTEILUNG DES SENATS (ANTWORT AUF GROẞE ANFRAGEN)',
    'MITTEILUNG DES SENATS (ANTWORT AUF  GROẞE ANFRAGE)'
  ]

  def self.extract_records(page)
    page.search('//tbody[@name="RecordRepeater"]')
  end

  def self.extract_detail_block(page)
    page.search('./tr[@name="Repeat_Fund"]/td[3]').first
  end

  def self.extract_full_reference(link)
    link.text.strip
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.extract_title(block)
    block.search('./tr[@name="Repeat_WHET"]/td[2]').first.text
  end

  def self.extract_url(link)
    path = link.attributes['href']
    Addressable::URI.parse(path).normalize.to_s
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

  def self.extract_meta(rows)
    if rows.first.text.match(/Kleine\s+Anfrage/m)
      results = rows.first.text.match(/Kleine\s+Anfrage\s+und\s+Antwort\s+des\s+Senats\s+vom\s+([\d\.]+),\s+Urheber:\s+(.+)/)
      return nil if results.nil?
      {
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        originators: results[2].strip,
        published_at: results[1]
      }
    else
      o_results = a_results = nil
      rows.each do |line|
        match = line.text.match(/Große\s+Anfrage\s+vom\s+.+,\s+Urheber:\s+(.+)/)
        o_results = match if match && !line.text.include?('Antwort')
        match = line.text.match(/Mitteilung\s+des\s+Senats\s+.+vom\s+([\d\.]+)/m)
        a_results = match if match
      end
      return nil if o_results.nil? || a_results.nil?
      {
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        originators: o_results[1].strip,
        published_at: a_results[1]
      }
    end
  end

  def self.extract_link(meta_rows)
    answer_row = meta_rows.select { |row| row.text.include?('Antwort') }
    answer_row.each do |row|
      link = row.search('a').find { |el| el.text.include?('/') }
      return link unless link.nil?
    end
    nil
  end

  def self.extract_paper(item)
    title = extract_title(item)
    meta_block = extract_detail_block(item)
    fail "HB [?]: no meta information found. Paper title: #{title}" if meta_block.nil?

    meta_rows = extract_meta_rows(item)
    link = extract_link(meta_rows)
    fail "HB [?]: no link element found. Paper title: #{title}" if link.nil?

    full_reference = extract_full_reference(link)
    url = extract_url(link)
    legislative_term, reference = extract_reference(full_reference)

    meta = extract_meta(meta_rows)
    fail "HB [#{full_reference}]: meta is nil." if meta.nil?

    originators = { people: [], parties: meta[:originators].split(',').map(&:strip) }
    published_at = Date.parse(meta[:published_at])

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: meta[:doctype],
      title: title,
      url: url,
      is_answer: true,
      originators: originators,
      answerers: { ministries: ['Senat'] },
      published_at: published_at,
      source_url: Detail.build_search_url(legislative_term, reference)
    }
  end

  class Overview < Scraper
    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      papers = []

      m = mechanize
      mp = m.get SEARCH_URL
      search_form = mp.form '__form'
      fail 'HB: search form missing' if search_form.nil?

      # fill search form
      search_form.field_with(name: '__action').value = 19
      search_form.field_with(name: '12_LISSH_WP').value = @legislative_term
      search_form.field_with(name: '07_LISSH_DTYP').value = TYPES.join('; ')
      # only search in landtag
      search_form.field_with(name: '11_LISSH_PARL').value = 'L'
      mp = m.submit(search_form)

      # Fail if no hits
      fail 'HB: search returns no results' if mp.search('//span[@name="HitCountZero"]').size > 0

      # get all papers on one page
      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 20
      search_form.field_with(name: 'LimitMaximumHitCount').options.find { |opt| opt.text.include? 'alle' }.select
      mp = m.submit(search_form)

      # switch to full view
      search_form = mp.form '__form'
      search_form.field_with(name: '__action').value = 50
      search_form.field_with(name: 'LISSH_Browse_ReportFormatList').value = 'LISSH_Vorgaenge_Report'
      mp = m.submit(search_form)

      items = BremenBuergerschaftScraper.extract_records(mp)
      items.each do |item|
        begin
          paper = BremenBuergerschaftScraper.extract_paper(item)
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
    def scrape
      m = mechanize
      mp = m.get(self.class.build_search_url(@legislative_term, @reference) + "&format=LISSH_Vorgaenge_Report")

      # Fail if no hits
      fail "HB [#{full_reference}]: search returns no results" if mp.search('//div[@name="NoReportGenerated"]/*').size > 0

      items = BremenBuergerschaftScraper.extract_records(mp)
      BremenBuergerschaftScraper.extract_paper(items.first)
    end

    def self.build_search_url(legislative_term, reference)
      BASE_URL + "/starweb/paris/servlet.starweb?path=paris/LISSHDOKFL.web&01_LISSHD_WP=#{legislative_term}&02_LISSHD_DNR=#{reference}"
    end
  end
end