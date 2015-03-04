require 'date'

module HamburgBuergerschaftScraper
  BASE_URL = 'http://www.buergerschaft-hh.de'
  TYPES = ['Schriftliche Kleine Anfrage', 'Große Anfrage']
  # because hamburg has a limit of displayed documents, we need to split the date range search
  # when scraping fails because of too much documents, increment this number, should not happen too often
  SEARCH_PARTS = 4

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/parldok/tcl/WPParse.tcl?template=FormFormalkriterien.htm'

    def supports_streaming?
      true
    end

    def scrape
      streaming = block_given?
      papers = []
      m = mechanize
      # to initialize session
      m.get SEARCH_URL
      # search form
      mp = m.get SEARCH_URL
      form = mp.forms.second
      field = form.field_with(name: 'LegislaturperiodenNummer')
      field.value = @legislative_term
      option_text = field.options.find { |option| option.text.include? "#{@legislative_term}. Wahlperiode" }.text
      dates = HamburgBuergerschaftScraper.extract_date_ranges(option_text)
      dates.each do |daterange|
        mp = submit_search(m, daterange)
        result_url = mp.uri
        result_page_index = 0
        loop do
          body = mp.search("//table[@id = 'parldokresult']")
          body.css('.pd_titel').each do |title_el|
            paper = HamburgBuergerschaftScraper.extract(title_el)
            if streaming
              yield paper
            else
              papers << paper
            end
          end
          break unless next_page_el(mp)
          result_page_index += 1
          mp = m.get("#{result_url}&pagepos=#{result_page_index}")
        end
      end
      papers unless streaming
    end

    def next_page_el(mp)
      # if there is no next page, a">>" becomes text ">>"
      mp.search("//a[text()[normalize-space(.)='>>']]").first
    end

    def submit_search(m, daterange)
      mp = m.get SEARCH_URL
      form = mp.forms.second
      form.field_with(name: 'LegislaturperiodenNummer').value = @legislative_term
      form.field_with(name: 'DatumVon').value = daterange.first.strftime('%d.%m.%Y')
      form.field_with(name: 'DatumBis').value = daterange.last.strftime('%d.%m.%Y')
      form.field_with(name: 'Dokumententyp').options.each do |opt|
        if TYPES.include? opt.text.strip
          opt.select
        else
          opt.unselect
        end
      end
      submit_button = form.submits.find { |btn| btn.value == 'Suchen' }
      mp = m.submit(form, submit_button)
      unless mp.forms.second.nil?
        form = mp.forms.second
        submit_button = form.submits.find { |btn| btn.value == 'Dokumente anzeigen' }
        mp = m.submit(form, submit_button)
      end
      if redir = mp.search("//meta[@http-equiv='refresh']").first
        mp = m.get BASE_URL + redir['content'].gsub(/.+URL=(.+)/m, '\1')
      end
      mp
    end
  end

  def self.extract_date_ranges(option_text)
    only_start_date = option_text.match(/\(.+\)/).nil?
    if only_start_date
      start_time = Date.strptime(option_text.split(' ').last.match(/([\d\.]+)$/)[1], '%d.%m.%y')
      end_time = Date.today
    else
      option_parts = option_text.match(/\((.+)\)/)[1].split('-')
      start_time = Date.strptime(option_parts.first.match(/([\d\.]+)/)[1], '%d.%m.%y')
      end_time = Date.strptime(option_parts.second.match(/([\d\.]+)/)[1], '%d.%m.%y')
    end
    if (end_time - start_time).to_i < 10
      return [[start_time, end_time]]
    end
    dates = start_time.step(end_time).to_a
    dates.each_slice((dates.size / SEARCH_PARTS.to_f).round).map { |group| [group.first, group.last] }
  end

  def self.extract(title_el)
    next_row = title_el.parent.next_element
    title_text = title_el.text.strip
    full_reference = next_row.element_children[0].text.strip
    reference = full_reference.split('/').last
    legislative_term = full_reference.split('/').first
    date = Date.parse(next_row.element_children[2].text.strip)
    path = title_el.element_children[0]['href']
    url = Addressable::URI.parse(BASE_URL + path).normalize.to_s

    doctype_el = next_row.element_children[1]
    if doctype_el.text.scan(/kleine/i).present?
      doctype = Paper::DOCTYPE_MINOR_INTERPELLATION
    elsif doctype_el.text.scan(/große/i).present?
      doctype = Paper::DOCTYPE_MAJOR_INTERPELLATION
    else
      fail "doctype unknown for Paper [HH #{full_reference}]"
    end

    originators = next_row.next_element.element_children[1].text.strip
    originators = NamePartyExtractor.new(originators).extract
    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: doctype,
      title: title_text,
      url: url,
      published_at: date,
      originators: originators
      # answerers are not available
    }
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/parldok/tcl/WPParse.tcl?template=FormDokumentNummer.htm'

    def scrape
      m = mechanize
      # get a session
      m.get SEARCH_URL
      mp = m.get SEARCH_URL
      form = mp.forms.second
      form.field_with(name: 'LegislaturperiodenNummer').value = @legislative_term
      form.field_with(name: 'Dokumentennummer').value = @reference
      submit_button = form.submits.find { |btn| btn.value == 'Suchen' }
      mp = m.submit(form, submit_button)
      # page which triggeres a redirect,so call redirect url manually
      redir = mp.search("//meta[@http-equiv='refresh']").first
      mp = m.get BASE_URL + redir['content'].gsub(/.+URL=(.+)/m, '\1')
      body = mp.search("//table[@id = 'parldokresult']")
      HamburgBuergerschaftScraper.extract(body.at_css('.pd_titel'))
    end
  end
end