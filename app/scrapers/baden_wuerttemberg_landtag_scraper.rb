require 'date'

module BadenWuerttembergLandtagScraper
  BASE_URL = 'http://www.landtag-bw.de'
  DETAIL_URL = 'http://www.statistik-bw.de/OPAL'

  def self.extract_result_links(page)
    page.search('//a[@class="doclist__item-link"]')
  end

  def self.extract_overview_meta(ol)
    items = ol.css('li')
    return nil if items.nil? || items.size < 3
    {
      full_reference: items[0].text.strip,
      published_at: Date.parse(items[1].text.strip.match(/Datum:\s+([\d\.]+)/)[1]),
      doctype: extract_doctype(items[2].text.strip.match(/Art:\s+(.+)/)[1]),
      originator_party: items[3].text.strip.match(/Urheber:\s+(.+)/)[1]
    }
  end

  def self.extract_reference(full_reference)
    full_reference.split('/')
  end

  def self.build_detail_url(legislative_term, reference)
    DETAIL_URL + "/Ergebnis.asp?WP=#{legislative_term}&DRSNR=#{reference}"
  end

  def self.get_detail_link(page)
    table = page.search('//table/tr/td[2]')
    table.at_css('a')
  end

  def self.link_is_answer?(link)
    !link.text.strip.match(/und\s+Antw/).nil?
  end

  def self.extract_doctype(match_result)
    case match_result.downcase
    when 'klanfr', 'klanf', 'kleine anfrage'
      Paper::DOCTYPE_MINOR_INTERPELLATION
    when 'granfr', 'granf', 'große anfrage'
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
  end

  def self.extract_detail_title(page)
    table = page.search('//table')
    table_rows = table.css('tr')
    table_rows.each do |row|
      if row.at_css('td').text == 'Betreff:'
        return row.element_children[1].text
      end
    end
    nil
  end

  def self.extract_meta(meta_text)
    match_results = meta_text.lstrip.match(/(KlAnfr?|GrAnfr?)\s+(.+?)\s*([\d\.\s]+)?\s+und\s+Antw\s+(?:(.+?)\s*([\d\.]+)?\s+)?Drs\s*(\d+\/\d+)/m)
    return nil if match_results.nil?
    doctype = extract_doctype(match_results[1])
    # when multiple originators exist, remove "and others" - we extract the other names later
    names = match_results[2].gsub(/\s+(?:u.a.|u.u.)/, '').strip
    if doctype == Paper::DOCTYPE_MINOR_INTERPELLATION
      originators = NamePartyExtractor.new(names, NamePartyExtractor::NAME_PARTY_COMMA).extract
    elsif doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
      parties = names.gsub(' und', ', ').split(',').map(&:strip)
      originators = { people: [], parties: parties }
    end

    ministries = []
    ministries = clean_ministries(match_results[4]) unless match_results[4].blank?

    {
      full_reference: match_results[6],
      doctype: doctype,
      published_at: Date.parse(match_results[3] || match_results[5]),
      originators: originators,
      answerers: { ministries: ministries }
    }
  end

  def self.clean_ministries(ministries)
    ministries.gsub("\n", ' ').gsub(' und', ',').split(',').map(&:strip)
  end

  def self.extract_overview_paper(link)
    block = link.next_element
    return nil if block.nil?

    title = link.text.strip
    meta = extract_overview_meta(block)
    full_reference = meta[:full_reference]
    legislative_term, reference = extract_reference(full_reference)

    url = link.attributes['href'].value
    url = Addressable::URI.parse(BASE_URL).join(url).normalize.to_s

    {
      full_reference: full_reference,
      legislative_term: legislative_term,
      reference: reference,
      doctype: meta[:doctype],
      title: title,
      url: url,
      published_at: meta[:published_at],
      # originator: people is set in detail scraper
      originators: { people: [], parties: [meta[:originator_party]] },
      # answerers is set in detail scraper
      # is_answer is set in detail scraper
      source_url: build_detail_url(legislative_term, reference)
    }
  end

  def self.extract_detail_paper(page)
    link = get_detail_link(page)
    title = extract_detail_title(page)
    url = link.attributes['href'].value

    meta = extract_meta(link.text)
    fail "Can't extract detail meta data from Paper [BW ?] text: #{link.text}" if meta.nil?

    full_reference = meta[:full_reference]
    legislative_term, reference = extract_reference(full_reference)

    {
      full_reference: full_reference,
      legislative_term: legislative_term,
      reference: reference,
      doctype: meta[:doctype],
      title: title,
      url: url,
      published_at: meta[:published_at],
      is_answer: link_is_answer?(link),
      originators: meta[:originators],
      answerers: meta[:answerers],
      source_url: build_detail_url(legislative_term, reference)
    }
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/cms/render/live/de/sites/LTBW/home/dokumente/drucksachen/contentBoxes/drucksachen.xhr?'
    TYPES = {
      Paper::DOCTYPE_MINOR_INTERPELLATION => 'KA',
      Paper::DOCTYPE_MAJOR_INTERPELLATION => 'GA'
    }

    def supports_streaming?
      true
    end

    def get_legislative_dates
      m = mechanize
      mp = m.get DETAIL_URL + '/'
      extract_legislative_dates(mp)
    end

    def extract_legislative_dates(legislative_page)
      select_options = legislative_page.form.field_with(name: 'WP').options
      select_options.each do |option|
        if option.value.to_i == @legislative_term
          period = option.text.match(/\d.+ Wahlperiode \((.+)-(.+)\)/)
          return [Date.parse(period[1]), Date.parse(period[2])]
        end
      end
      nil
    end

    def self.search_url(base, type, legislative_begin, legislative_end, offset)
      url = base.dup
      url << 'initiativeType=' + type + '&'
      url << 'sachstandBegin=' + legislative_begin.strftime('%d.%m.%Y') + '&'
      url << 'sachstandEnd=' + legislative_end.strftime('%d.%m.%Y') + '&'
      url << 'offset=' + offset.to_s
      url
    end

    def scrape
      streaming = block_given?
      papers = []
      m = mechanize
      legislative_begin, legislative_end = get_legislative_dates

      TYPES.each do |type, url_type|
        offset = 0
        loop do
          begin
            page = m.get self.class.search_url(SEARCH_URL, url_type, legislative_begin, legislative_end, offset)
          rescue Mechanize::ResponseReadError => e
            page = e.force_parse
          end

          links = BadenWuerttembergLandtagScraper.extract_result_links(page)
          break if links.nil? || links.size == 0

          links.each do |link|
            begin
              paper = BadenWuerttembergLandtagScraper.extract_overview_paper(link)
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

          offset = offset + 10
        end
      end
      papers unless streaming
    end
  end

  class Detail < DetailScraper
    def scrape
      m = mechanize
      page = m.get BadenWuerttembergLandtagScraper.build_detail_url(@legislative_term, @reference)
      BadenWuerttembergLandtagScraper.extract_detail_paper(page)
    end
  end
end