require 'date'

module BundestagScraper
  BASE_URL = 'http://dipbt.bundestag.de'
  OVERVIEW_URL = BASE_URL + '/extrakt/ba'
  START_URL = BASE_URL + '/dip21.web/bt'

  class Overview < Scraper
    TYPES = ['Kleine Anfrage', 'Große Anfrage']

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      # increase read timeout for the large export page
      m.read_timeout = (m.read_timeout || 60) * 2

      # need to open start page first, it sets some required session cookies
      m.get START_URL

      # get export
      term_url = "#{OVERVIEW_URL}/WP#{@legislative_term}/"
      mp = m.get term_url
      table = mp.search "//table[contains(@summary, 'Beratungsabläufe')]"

      papers = []
      table.css('tbody tr').each do |row|
        type = row.css('td')[0].text
        link = row.at_css('td a')
        detail_url = link.attributes['href'].value

        next unless TYPES.include?(type)

        begin
          begin
            detail_url = Addressable::URI.join(term_url, detail_url).normalize.to_s
            detail_page = m.get detail_url
            paper = BundestagScraper.scrape_vorgang(detail_page, detail_url)
          rescue BundestagScraper::MissingPaperOnDetailError => err
            fail err if err.full_url.nil?
            detail_page = m.get err.full_url
            begin
              paper = BundestagScraper.go_and_scrape_procedure_page(m, err, detail_page, detail_url)
            rescue BundestagScraper::MissingProcedureDataError => err
              paper = BundestagScraper.go_and_scrape_procedure_page(m, err, err.page, detail_url)
            end
          end
        rescue => e
          logger.warn "url=#{detail_url} error=\"#{e}\" backtrace=#{Rails.backtrace_cleaner.clean(e.backtrace).to_json}"
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

      v = nil
      begin
        v = BundestagScraper.scrape_vorgang(detail_page, detail_url)
      rescue BundestagScraper::MissingPaperOnDetailError => err
        fail err if err.full_url.nil?
        detail_page = m.get err.full_url
        v = BundestagScraper.go_and_scrape_procedure_page(m, err, detail_page, detail_url)
      rescue BundestagScraper::MissingProcedureDataError => err
        v = BundestagScraper.go_and_scrape_procedure_page(m, err, err.page, detail_url)
      end
      v
    end
  end

  def self.go_and_scrape_procedure_page(m, err, page, url)
    vorgangsablauf_link = page.at_css('.contentBox .tabReiter li a')
    fail err if vorgangsablauf_link.nil?
    page = m.click(vorgangsablauf_link)
    scrape_procedure_page(page, url, err.extract)
  end

  class MissingPaperOnDetailError < StandardError
    attr_reader :extract, :full_url
    def initialize(msg = "No paper found on detail page", extract = nil, full_url = nil)
      @extract = extract
      @full_url = full_url
      super(msg)
    end
  end

  class MissingProcedureDataError < StandardError
    attr_reader :extract, :page
    def initialize(msg = "No procedure data found on page", extract = nil, page = nil)
      @extract = extract
      @page = page
      super(msg)
    end
  end

  def self.scrape_vorgang(page, detail_url)
    begin
      scrape_content(page.content, detail_url)
    rescue MissingPaperOnDetailError => err
      full_link = extract_full_link(page)
      fail "#{detail_url}: ignored, no paper found" if full_link.blank?
      full_url = full_link.attributes['href'].value
      full_url = Addressable::URI.join(BASE_URL, full_url).normalize.to_s
      raise MissingPaperOnDetailError.new("#{detail_url}: no paper found", err.extract, full_url)
    rescue MissingProcedureDataError => err
      raise MissingProcedureDataError.new("#{detail_url}: no procedure data found", err.extract, page)
    end
  end

  def self.scrape_content(content, detail_url)
    doc = extract_doc(content)

    doctype = extract_doctype(doc)
    fail "#{detail_url}: doctype unknown: #{doctype}" if doctype.blank?

    status = extract_status(doc)
    fail "#{detail_url}: ignored, status: #{status}" unless status == 'Beantwortet'

    title = extract_title(doc)
    legislative_term = doc.at_css('VORGANG WAHLPERIODE').text.to_i

    found = false
    doc.css('WICHTIGE_DRUCKSACHE').each do |node|
      next unless node.at_css('DRS_TYP').text == 'Antwort'
      next if node.at_css('DRS_LINK').nil?
      found = true
    end
    extract = {
      legislative_term: legislative_term,
      doctype: doctype,
      title: title,
      source_url: detail_url
    }
    raise MissingPaperOnDetailError.new("#{detail_url}: no paper found", extract) unless found

    pr = extract_procedure_xml(doc)
    # this happens, if the export linked directly to the system. trigger procedure page scrape
    raise MissingProcedureDataError.new("#{detail_url}: no date found", extract) if pr[:date].nil?

    pr = convert_extract(pr)
    extract.merge(pr).merge({
      is_answer: true
    })
  end

  def self.scrape_procedure_page(page, detail_url, extract)
    scrape_procedure(page.content, detail_url, extract)
  end

  def self.scrape_procedure(content, detail_url, extract)
    doc = extract_doc(content)
    pr = extract_procedure_xml(doc)
    fail "#{detail_url}: not yet answered" if pr[:is_answer].nil? || pr[:is_answer] == false

    pr = convert_extract(pr)
    extract.merge(pr)
  end

  def self.extract_procedure_xml(doc)
    originators = { people: [], parties: [] }
    answerers = { ministries: [] }
    date = nil
    full_reference = nil
    url = nil
    is_answer = false

    doc.css('VORGANGSABLAUF VORGANGSPOSITION').each do |node|
      urheber = node.at_css('URHEBER').text
      next if urheber.include?('Beratung')
      if urheber.include?('Antwort') || urheber.include?('Bundesregierung')
        fundstelle = node.at_css('FUNDSTELLE').text
        _, full_reference = fundstelle.match(/\s+(\d+\/\d+)/).to_a
        url = node.at_css('FUNDSTELLE_LINK').try(:text).try(:strip)
        is_answer = !url.nil?
      end
      # originator entry should always have a 'PERSOENLICHER_URHEBER'
      is_ministry = node.at_css('PERSOENLICHER_URHEBER').nil?
      if is_ministry
        _, ministry = urheber.match(/.*?,(?:\s+Urheber\s+:)?\s+([^(]*)/).to_a
        unless ministry.nil?
          ministry = ministry.strip.sub(/^Bundesregierung,\s+/, '')
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
          party = unode.at_css('FRAKTION').try(:text)
          originators[:parties] << party unless originators[:parties].include? party
        end
      end
    end

    {
      full_reference: full_reference,
      answerers: answerers,
      date: date,
      originators: originators,
      url: url,
      is_answer: is_answer
    }
  end

  def self.convert_extract(extract)
    extract[:published_at] = Date.parse(extract.delete(:date))
    extract[:reference] = extract[:full_reference].split('/').last
    extract[:url] = Addressable::URI.join(BASE_URL, extract[:url]).normalize.to_s
    extract
  end

  def self.extract_full_link(doc)
    doc.css('.linkExtern').select { |x| x.text.include? 'Weitere Details' }.first
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
    fail 'no embedded xml found' if comment_start.nil?
    comment_end = content.index('-->', comment_start)
    xml = content[comment_start...comment_end]
    xml = xml.strip.gsub(/<-.*->/, '') # remove nested "comments"
    Nokogiri.parse xml
  end

  def self.extract_type(doc)
    doc.at_css('VORGANG VORGANGSTYP').text
  end
end