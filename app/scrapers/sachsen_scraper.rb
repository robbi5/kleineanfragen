module SachsenScraper
  BASE_URL = 'http://edas.landtag.sachsen.de'

  def self.extract_overview_items(page)
    page.search('//td[@class="dxdvItem_EDAS"]/table')
  end

  def self.extract_title(item)
    item.search('.//tr[3]/td/b').text.strip
  end

  def self.extract_meta_text(item)
    t = item.search('.//tr[3]/td').text.split("\n").find{ |t| t.include?('KlAnfr') || t.include?('GrAnfr') }
    t.strip[6..t.length]
  end

  def self.extract_date(meta_text)
    Date.parse(meta_text.match(/\d+\.\d+\.\d{4}/).to_s)
  end

  def self.extract_reference(meta_text)
    meta_text.split('Drs')[1].strip
  end

  def self.extract_originators(meta_text)
    people = [meta_text.partition(/\p{Upper}{2}/)[0].strip]
    parties = [meta_text.match(/\p{Upper}\p{Upper}+\s*\p{Upper}*/)[0].strip]
    originators = { people: people, parties: parties}
  end

  def self.extract_overview_paper(item, doctype)
    meta_text = extract_meta_text item
    full_reference = extract_reference(meta_text);
    {
      legislative_term: full_reference.split('/')[0],
      full_reference: full_reference,
      reference: full_reference.split('/')[1],
      doctype: doctype,
      title: extract_title(item),
      url: '',
      published_at: extract_date(meta_text),
      originators: extract_originators(meta_text),
      is_answer: nil,
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/parlamentsdokumentation/parlamentsarchiv/dokumententyp.aspx'

    def supports_streaming?
      true
    end

    def scrape
      m = mechanize
      top = m.get 'http://edas.landtag.sachsen.de'
      content = top.frame_with(name: 'content').click
      # suche
      search_form = content.forms.first
      search_form['ctl00_masterContentCallback_content_suchmaske_tblSearch_tabSuche_panelUmSuchmaskeEinfach_suchmaskeEinfachCallback_sb_EinfDoktyp_ec_VI'] = 'KlAnfr'
      search_form['__EVENTARGUMENT'] = 'Click'
      search_form['__EVENTTARGET'] =
        'ctl00$masterContentCallback$content$suchmaske$tblSearch$tabSuche$panelUmSuchmaskeEinfach$suchmaskeEinfachCallback$btn_EinfSuche'
      content = search_form.submit

      page = 1
      papers = []
      while !content.search('//td[@class="dxdvItem_EDAS"]/table').nil? do

        SachsenScraper.extract_overview_items(content).each do |item|
          paper = SachsenScraper.extract_overview_paper(item, Paper::DOCTYPE_MINOR_INTERPELLATION)
          puts paper
          papers.push(paper) if !paper.nil?
        end
        page += 1
        content = m.get('http://edas.landtag.sachsen.de/parlamentsdokumentation/parlamentsarchiv/trefferliste.aspx?NavSeite=' + page.to_s + '&isHaldeReport=&VolltextSuche=&refferer=')
      end
    end
  end

  class Detail < DetailScraper

  end
end
