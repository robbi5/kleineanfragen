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
    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: extract_title(item),
      # url
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

  class Detail < DetailScraper
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
      end
      paper
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

    def search(content, type, high_doc_number)
      if type == Paper::DOCTYPE_MAJOR_INTERPELLATION
        type = 'GrAnfr'
      else
        type = 'KlAnfr'
      end
      search_form = content.forms.first
      search_form['__EVENTARGUMENT'] = 'Click'
      search_form['__EVENTTARGET'] = SEARCH_FIELD + '$btn_EinfSuche'
      search_form[SEARCH_FIELD + '$tf_EinfDoknrVon$ec'] = 1
      search_form[SEARCH_FIELD + '$tf_EinfDoknrBis$ec'] = high_doc_number
      search_form[SEARCH_FIELD2 + 'OrderBy_logisch_ec_VI'] = 'Eingangsdatum_desc'
      search_form[SEARCH_FIELD2 + 'Doktyp_ec_VI'] = type
      search_form.submit
    end

    def supports_streaming?
      true
    end

    def scrape_type(m, type, high_doc_number, &block)
      top = m.get BASE_URL
      SachsenScraper.switch_to_term(@legislative_term, m, top)
      content = top.frame_with(name: 'content').click
      content = search(content, type, high_doc_number)

      page = 1
      paper = nil
      while !content.search('//td[@class="dxdvItem_EDAS"]/table')[0].nil?
        SachsenScraper.extract_overview_items(content).each do |item|
          begin
            paper = SachsenScraper.extract_overview_paper(item, type)
          rescue => e
            logger.warn e
            next
          end
          next if paper.nil?
          yield paper
        end
        page += 1
        content = m.get(BASE_URL + '/parlamentsdokumentation/parlamentsarchiv/trefferliste.aspx?NavSeite=' + page.to_s + '&isHaldeReport=&VolltextSuche=&refferer=')
      end
      if !content.search('//*[@id="ctl00_masterContentCallback_content_trWarning"]')[0].nil?
        scrape_type(m, type, paper[:reference].to_i - 1, &block)
      end
    end

    def scrape(&block)
      high_doc_number = 20000
      papers = []
      block = -> (paper) { papers << paper } unless block_given?
      m = mechanize
      scrape_type(m, Paper::DOCTYPE_MINOR_INTERPELLATION, high_doc_number, &block)
      scrape_type(m, Paper::DOCTYPE_MAJOR_INTERPELLATION, high_doc_number, &block)
      papers unless block_given?
    end
  end
end
