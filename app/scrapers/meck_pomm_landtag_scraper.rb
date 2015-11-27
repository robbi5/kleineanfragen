require 'date'

module MeckPommLandtagScraper
  BASE_URL = 'http://www.dokumentation.landtag-mv.de'

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/Parldok/formalkriterien'
    TYPES = ['Kleine Anfrage und Antwort', 'Große Anfrage und Antwort']

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      m = mechanize
      # get a session
      m.get SEARCH_URL
      mp = m.get SEARCH_URL

      search_form = mp.forms.second
      search_form = fill_search_form(search_form)
      submit_button = search_form.submits.find { |btn| btn.value == 'Suchen' }
      mp = m.submit(search_form, submit_button)

      papers = []
      loop do
        body = mp.search("//table[@id = 'parldokresult']")
        body.css('.title').each do |title_el|
          paper = MeckPommLandtagScraper.extract(title_el)
          if streaming
            yield paper
          else
            papers << paper
          end
        end

        break unless next_page_el(mp)
        mp = m.click next_page_el(mp)
      end
      papers unless streaming
    end

    def fill_search_form(form)
      form.field_with(name: 'LegislaturperiodenNummer').value = @legislative_term
      form.field_with(name: 'DokumententypId').options.each do |opt|
        if TYPES.include? opt.text.strip
          opt.select
        else
          opt.unselect
        end
      end
      form
    end

    def next_page_el(mp)
      # if there is no next page, a">>" becomes a span">>"
      mp.search("//a[text()[normalize-space(.)='>>']]").first
    end
  end

  def self.extract(title_el)
    next_row = title_el.parent.next_element
    title_text = title_el.text.strip
    full_reference = next_row.element_children[0].text.strip
    reference = full_reference.split('/').last
    legislative_term = full_reference.split('/').first
    date = Date.parse(next_row.element_children[2].text.strip)
    path = title_el.element_children[0]['href']
    url = Addressable::URI.parse(BASE_URL).join(path).normalize.to_s

    doctype_el = next_row.element_children[1]
    if doctype_el.text.scan(/kleine/i).present?
      doctype = Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif doctype_el.text.scan(/große/i).present?
      doctype = Paper::DOCTYPE_MAJOR_INTERPELLATION
    else
      fail "doctype unknown for Paper [MV #{full_reference}]"
    end

    ministries = []
    meta_row = next_row.next_element.element_children[1].text.strip
    match_ministry = meta_row.match(/.+,\s+Landesregierung\s+\((.+)\)/)
    originators = meta_row.match(/(.+),\s+(?:Landesregierung|Ausschuss)/)
    if !originators.nil?
      if NamePartyExtractor.looks_like_party?(originators[1])
        originators = { people: [], parties: [originators[1]] }
      else
        originators = NamePartyExtractor.new(originators[1]).extract
      end
    end
    if originators.nil? && doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
      originators = { people: [], parties: [meta_row] }
    end
    if match_ministry
      ministries << match_ministry[1]
    end
    if ministries.empty? && meta_row.match(/Ausschuss/)
      has_name = meta_row.match(/(Ausschuss)(\s+.+)/)
      if has_name
        ministries << has_name[1].gsub('Ausschuss', 'Ministerium') + has_name[2]
      else
        ministries << 'Landesregierung'
      end
    end
    if ministries.empty? && meta_row.match(/Landesregierung/)
      ministries << 'Landesregierung'
    end

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title_text,
      url: url,
      published_at: date,
      originators: originators,
      answerers: { ministries: ministries }
    }
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/Parldok/dokumentennummer'

    def scrape
      m = mechanize
      # get a session
      m.get SEARCH_URL
      mp = m.get SEARCH_URL

      search_form = mp.forms.second
      search_form.field_with(name: 'LegislaturPeriodenNummer').value = @legislative_term
      search_form.field_with(name: 'DokumentenNummer').value = @reference
      submit_button = search_form.submits.find { |btn| btn.value == 'Suchen' }
      mp = m.submit(search_form, submit_button)
      body = mp.search("//table[@id = 'parldokresult']")
      MeckPommLandtagScraper.extract(body.at_css('.title'))
    end
  end
end