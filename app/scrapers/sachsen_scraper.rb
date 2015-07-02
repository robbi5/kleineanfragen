module SachsenScraper
  BASE_URL = 'http://edas.landtag.sachsen.de'
  SEARCH_FIELD = 'ctl00$masterContentCallback$content$suchmaske$tblSearch$tabSuche$panelUmSuchmaskeEinfach$suchmaskeEinfachCallback'
  SEARCH_FIELD2 =
    'ctl00_masterContentCallback_content_suchmaske_tblSearch_tabSuche_panelUmSuchmaskeEinfach_suchmaskeEinfachCallback_sb_Einf'

  def self.extract_overview_items(page)
    page.search('//td[@class="dxdvItem_EDAS"]/table')
  end

  def self.extract_title(item)
    item.search('.//tr[3]/td/b').text.strip
  end

  def self.extract_meta_text(item)
    text = item.search('.//tr[3]/td').text.split("\n").find{ |t| t.include?('KlAnfr') || t.include?('GrAnfr') }
    text.strip if !text.nil?
  end

  def self.extractType(text)
    if (text[0..5] == 'KlAnfr')
      Paper::DOCTYPE_MINOR_INTERPELLATION
    else
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
  end

  def self.extract_date(meta_text)
    Date.parse(meta_text.match(/\d+\.\d+\.\d{4}/).to_s)
  end

  def self.extract_reference(meta_text)
    meta_text.split('Drs')[1].strip
  end

  def self.extract_originators(meta_text)
    people = [meta_text.partition(/\p{Upper}{2}/)[0].strip]
    parties = [meta_text.match(/\p{Upper}\p{Lower}*\p{Upper}+\s*\p{Upper}*/)[0].strip]
    originators = { people: people, parties: parties}
  end

  def self.extract_overview_paper(item, doctype)
    meta_text = extract_meta_text item
    meta_text = meta_text[6..meta_text.length].strip
    full_reference = extract_reference(meta_text)
    {
      legislative_term: full_reference.split('/')[0],
      full_reference: full_reference,
      reference: full_reference.split('/')[1],
      doctype: doctype,
      title: extract_title(item),
      url: nil,
      published_at: extract_date(meta_text),
      originators: extract_originators(meta_text),
      is_answer: nil,
    }
  end

  def self.extract_detail_paper(item)
    meta_text = extract_meta_text(item)
    type = extractType(meta_text)
    extract_overview_paper(item, type)
  end

  def self.switchToTerm(i, m, top)
    nav = top.frame_with(name: 'head').click
    nav = m.get("/redirect.aspx?wahlperiode=" + i.to_s)
    nav.forms.first.submit
  end

  class Detail < DetailScraper
    def scrape
      m = mechanize
      top = m.get BASE_URL
      SachsenScraper.switchToTerm(@legislative_term, m, top)
      content = top.frame_with(name: 'content').click
      content = searchDetail(content)
      paper = nil
      SachsenScraper.extract_overview_items(content).each do |item|
        paper = SachsenScraper.extract_detail_paper(item)
        content = m.click(item.search('//a').first)
        answeredDate = content.search('//*[@id="ctl00_masterContentCallback_content_tabTreffer_trefferDataView_IT0_HyperLink6"]').first
        if (answeredDate.nil? || answeredDate.text.empty?)
          paper[:is_answer] = false
        else
          paper[:is_answer] = true
          paper[:published_at] = SachsenScraper.extract_date(answeredDate.text)
          top = m.get(extract_viewer_url(content))
          pdfurl = extract_pdf_url(top)
          paper[:url] = pdfurl
        end
      end
      paper
    end

    def extract_pdf_url(top)
      nav = top.frame_with(name: 'navigation').click
      onloadValue = nav.search("//body").first.attribute("onload")
      pdfurl = onloadValue.to_s[/(http\S*?\.pdf)/]
    end

    def extract_viewer_url(content)
      pdfTable = content.search('//table[@id="ctl00_masterContentCallback_content_tabTreffer_trefferDataView_IT0_anzeige_tblButtons"]').first
      viewerIds = pdfTable.search('//input').select do |i|
        !i.attribute('name').nil? && !i.attribute('name').value.nil? && !i.attribute('name').value.index(/no\$btn/).nil?
      end
      viewerIds = viewerIds.map do |i|
        i.attribute('name').value
      end
      viewerId = viewerIds.last.match(/anzeige\$(.*?)_(.*?)_Drs_(.*?)_no\$btn/)
      "http://edas.landtag.sachsen.de/viewer.aspx?dok_nr=" + viewerId[1] + "&dok_art=Drs&leg_per=" + viewerId[3] + "&pos_dok="+ viewerId[2]
    end

    def searchDetail(content)
      search_form = content.forms.first
      search_form[SEARCH_FIELD+'$tf_EinfDoknrVon$ec'] = @reference.to_s
      search_form['__EVENTARGUMENT'] = 'Click'
      search_form['__EVENTTARGET'] = SEARCH_FIELD+'$btn_EinfSuche'
      search_form.submit
    end
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/parlamentsdokumentation/parlamentsarchiv/dokumententyp.aspx'

    def search(content, type, startAt)
      if (type == Paper::DOCTYPE_MAJOR_INTERPELLATION)
        type = 'GrAnfr'
      else
        type = 'KlAnfr'
      end
      search_form = content.forms.first
      search_form['__EVENTARGUMENT'] = 'Click'
      search_form['__EVENTTARGET'] = SEARCH_FIELD + '$btn_EinfSuche'
      search_form[SEARCH_FIELD + '$tf_EinfDoknrVon$ec'] = startAt
      search_form[SEARCH_FIELD + '$tf_EinfDoknrBis$ec'] = 100000
      # TODO switch startAt
      #search_form[SEARCH_FIELD2 + 'OrderBy_logisch_ec_VI'] = 'Eingangsdatum_desc'
      search_form[SEARCH_FIELD2 + 'Doktyp_ec_VI'] = type
      content = search_form.submit
    end

    def supports_pagination?
      false
    end

    def supports_streaming?
      true
    end

    # TODO switch around startAt
    def scrapeType(m, type, startAt, &block)
      top = m.get BASE_URL
      SachsenScraper.switchToTerm(@legislative_term, m, top)
      content = top.frame_with(name: 'content').click
      content = search(content, type, startAt)

      page = 1
      while !content.search('//td[@class="dxdvItem_EDAS"]/table')[0].nil? do
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
      if (!content.search('//*[@id="ctl00_masterContentCallback_content_trWarning"]')[0].nil?)
        scrapeType(m, type, papers.last.reference.to_i + 1, &block)
      end
    end

    def scrape(&block)
      papers = []
      block = -> (paper) { papers << paper } unless block_given?
      m = mechanize
      scrapeType(m, Paper::DOCTYPE_MAJOR_INTERPELLATION, 1, &block)
      scrapeType(m, Paper::DOCTYPE_MINOR_INTERPELLATION, 1, &block)
      papers unless block_given?
    end
  end
end
