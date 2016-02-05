module SachsenScraper
  BASE_URL = 'http://edas.landtag.sachsen.de'
  SEARCH_FIELD = 'ctl00$masterContentCallback$content$suchmaske$tblSearch$tabSuche$panelUmSuchmaskeEinfach$suchmaskeEinfachCallback'
  SEARCH_FIELD2 =
    'ctl00_masterContentCallback_content_suchmaske_tblSearch_tabSuche_panelUmSuchmaskeEinfach_suchmaskeEinfachCallback_sb_Einf'

  def self.extract_overview_items(page)
    page.search('//td[@class="dxdvItem_EDAS"]/table')
  end

  def self.extract_title(item)
    el = item.search('.//tr[3]/td/b')
    el.css('br').each { |br| br.replace ' ' }
    el.text.strip
  end

  def self.extract_meta_text(item)
    text = item.search('.//tr[3]/td').text.split("\n").find { |t| t.include?('KlAnfr') || t.include?('GrAnfr') }
    text.strip if !text.nil?
  end

  def self.extract_meta_data(text)
    type = extract_type(text)
    m = text.match(/^(?:Gr|Kl)Anfr (.+?) ([\d\.]+) Drs ([\d\/]+)$/)
    return nil if m.nil?
    if type == Paper::DOCTYPE_MAJOR_INTERPELLATION
      party = m[1].strip
      originators = { people: [], parties: [party] }
    else
      originators = NamePartyExtractor.new(m[1], NamePartyExtractor::NAME_PARTY_COMMA).extract
    end
    {
      originators: originators,
      published_at: Date.parse(m[2]),
      full_reference: m[3]
    }
  end

  def self.extract_type(text)
    if text[0..5] == 'KlAnfr'
      Paper::DOCTYPE_MINOR_INTERPELLATION
    else
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
  end

  def self.extract_date(meta_text)
    Date.parse(meta_text.match(/\d+\.\d+\.\d{4}/).to_s)
  end

  def self.extract_overview_paper(item, doctype)
    meta_text = extract_meta_text(item)
    meta = extract_meta_data(meta_text)
    fail "SN: cannot extract meta data: #{meta_text}" if meta.nil?
    full_reference = meta[:full_reference]
    legislative_term, reference = full_reference.split('/')

    # check answered?
    answer_soon_text = item.search('.//tr[2]/td[2]').try(:text).try(:strip)
    if !answer_soon_text.nil? && answer_soon_text.include?('Frist SReg')
      fail "[SN #{full_reference}] not yet - #{answer_soon_text}"
    end

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: extract_title(item),
      # url is unknown in this step
      url: nil,
      published_at: meta[:published_at],
      originators: meta[:originators],
      is_answer: nil
    }
  end

  def self.extract_detail_paper(item)
    meta_text = extract_meta_text(item)
    type = extract_type(meta_text)
    extract_overview_paper(item, type)
  end

  def self.switch_to_term(legislative_term, m, top)
    top.frame_with(name: 'head').click
    nav = m.get('/redirect.aspx?wahlperiode=' + legislative_term.to_s)
    nav.forms.first.submit
  end

  def self.has_pagination?(contents)
    script = contents.search('//div[@id="ctl00_masterContentCallback"]/script').try(:text)
    return false if script.nil?
    m = script.match(/v_i_show\s+=\s+([\-\d]+);/)
    return false if m.nil?
    m[1] != '0'
  end

  class Detail < DetailScraper
    def initialize(*)
      super
      @sleep = 3
    end

    def scrape
      m = mechanize
      top = m.get BASE_URL
      SachsenScraper.switch_to_term(@legislative_term, m, top)
      content = top.frame_with(name: 'content').click
      content = search_detail(content)
      paper = nil
      SachsenScraper.extract_overview_items(content).each do |item|
        paper = SachsenScraper.extract_detail_paper(item)
        # get detail page
        content = m.click(item.search('//a').first)
        answered_at = self.class.extract_answered_at(content)
        if !answered_at.nil? && !answered_at.text.empty?
          # answered_at only contains the date. but is that even correct?
          paper[:published_at] = SachsenScraper.extract_date(answered_at.text)
          buttons = self.class.extract_pdf_buttons(content)
          # the first button is for the question, the second one for the answer
          if buttons.size > 1
            paper[:is_answer] = true
            top = m.get(self.class.extract_viewer_url(buttons.last))
            pdf_url = self.class.extract_pdf_url(top)
            paper[:url] = pdf_url
          end
        end
        vpage = m.get(BASE_URL + "/parlamentsdokumentation/parlamentsarchiv/treffer_vorgang.aspx?VorgangButton=y&refferer=&dok_art=Drs&leg_per=#{paper[:legislative_term]}&dok_nr=#{paper[:reference]}")
        answerer = self.class.extract_vorgang_answerer(vpage)
        paper[:answerers] = { ministries: [answerer] } unless answerer.nil?
      end
      paper
    end

    def self.extract_vorgang_answerer(vpage)
      paper_table = vpage.search('//div[@class="dxtc-content"]//td[@class="text"]//table')
      rows = paper_table.search('.//td[@class="text"]')
      rows.each do |row|
        next unless row.text.include? 'Antw'
        return row.text.match(/Antw (.+) \d+\./).try(:[], 1)
      end
      nil
    end

    def self.extract_answered_at(content)
      content.search('//*[@id="ctl00_masterContentCallback_content_tabTreffer_trefferDataView_IT0_HyperLink6"]').first
    end

    def self.extract_pdf_url(top)
      nav = top.frame_with(name: 'navigation').click
      onload_value = nav.search('//body').first.attribute('onload')
      onload_value.to_s[/(http\S*?\.pdf)/]
    end

    def self.extract_pdf_buttons(content)
      pdf_table = content.search('//table[@id="ctl00_masterContentCallback_content_tabTreffer_trefferDataView_IT0_anzeige_tblButtons"]').first
      return [] if pdf_table.nil?
      viewer_ids = pdf_table.search('.//input').select do |i|
        !i.attribute('name').nil? && !i.attribute('name').value.nil? && !i.attribute('name').value.index(/no\$btn/).nil?
      end
      viewer_ids.map { |i| i.attribute('name').value }
    end

    def self.extract_viewer_url(button)
      viewer_id = button.match(/anzeige\$(.*?)_(.*?)_Drs_(.*?)_no\$btn/)
      'http://edas.landtag.sachsen.de/viewer.aspx?dok_nr=' + viewer_id[1] + '&dok_art=Drs&leg_per=' + viewer_id[3] + '&pos_dok=' + viewer_id[2]
    end

    def search_detail(content)
      search_form = content.forms.first
      search_form[SEARCH_FIELD + '$tf_EinfDoknrVon$ec'] = @reference.to_s
      search_form['__EVENTARGUMENT'] = 'Click'
      search_form['__EVENTTARGET'] = SEARCH_FIELD + '$btn_EinfSuche'
      search_form.submit
    end
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/parlamentsdokumentation/parlamentsarchiv/dokumententyp.aspx'

    def initialize(*)
      super
      @sleep = 3
    end

    def supports_streaming?
      true
    end

    def supports_typed_pagination?
      true
    end

    def mech
      @mech ||= mechanize
    end

    def init_scrape(type, from, to)
      top = mech.get BASE_URL
      SachsenScraper.switch_to_term(@legislative_term, mech, top)
      content = top.frame_with(name: 'content').click
      search(content, type, from, to)
      @initialized = true
      @last_type = type
    end

    def search(content, type, from, to)
      if type == Paper::DOCTYPE_MAJOR_INTERPELLATION
        type = 'GrAnfr'
      else
        type = 'KlAnfr'
      end
      search_form = content.forms.first
      search_form['__EVENTARGUMENT'] = 'Click'
      search_form['__EVENTTARGET'] = SEARCH_FIELD + '$btn_EinfSuche'
      search_form[SEARCH_FIELD + '$tf_EinfDoknrVon$ec'] = from
      search_form[SEARCH_FIELD + '$tf_EinfDoknrBis$ec'] = to
      search_form[SEARCH_FIELD2 + 'OrderBy_logisch_ec_VI'] = 'Eingangsdatum_desc'
      search_form[SEARCH_FIELD2 + 'Doktyp_ec_VI'] = type
      search_form.submit
    end

    def scrape_page(page, type, &block)
      content = mech.get(BASE_URL + '/parlamentsdokumentation/parlamentsarchiv/trefferliste.aspx?NavSeite=' + page.to_s + '&isHaldeReport=&VolltextSuche=&refferer=')

      SachsenScraper.extract_overview_items(content).each do |item|
        paper = nil
        begin
          paper = SachsenScraper.extract_overview_paper(item, type)
        rescue => e
          logger.warn e
          next
        end
        next if paper.nil?
        yield paper
      end
      content
    end

    def scrape_type(type, from, to, &block)
      page = 1
      last_paper = nil
      content = nil
      init_scrape(type, from, to)
      loop do
        content = scrape_page(page, type) do |p|
          last_paper = p
          block.call(p)
        end
        break if !content.search('//td[@class="dxdvItem_EDAS"]/table')[0].nil?
        page += 1
      end
      if !content.search('//*[@id="ctl00_masterContentCallback_content_trWarning"]')[0].nil?
        # didn't get all papers
        # use the last document number and search from there again
        # - we sort DESC, from is a small number again, to is our last paper - 1
        scrape_type(type, from, last_paper[:reference].to_i - 1, &block)
      end
    end

    def scrape(&block)
      high_doc_number = 20000
      papers = []
      block = -> (paper) { papers << paper } unless block_given?
      scrape_type(Paper::DOCTYPE_MINOR_INTERPELLATION, 1, high_doc_number, &block)
      scrape_type(Paper::DOCTYPE_MAJOR_INTERPELLATION, 1, high_doc_number, &block)
      papers unless block_given?
    end

    def scrape_paginated_type(type, page, &block)
      high_doc_number = 20000
      init_scrape(type, 1, high_doc_number) if !@initialized || @last_type != type
      content = scrape_page(page, type, &block)
      SachsenScraper.has_pagination?(content)
    end
  end
end
