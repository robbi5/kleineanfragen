require 'date'

module BadenWuerttembergLandtagScraper
  BASE_URL = 'http://www.landtag-bw.de'
  DETAIL_URL = 'http://www.statistik-bw.de/OPAL'
  SEARCH_URL = 'https://parlis.landtag-bw.de'

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

  def self.get_detail_url(legislative_term, reference)
    SEARCH_URL + "/parlis/browse.tt.html?type=&action=qlink&q=WP=#{legislative_term}%20AND%20DNRF=#{reference}"
  end

  def self.get_report_url(m, legislative_term, reference)
    hashbody = {
      "action" => "SearchAndDisplay",
      "sources" => ["Star"],
      "report" => {
        "rhl" => "main",
        "rhlmode" => "add",
        "format" => "suchergebnis-dokumentnummer",
        "mime" => "html",
        "sort" => "sDNRSO sRNRDS"
      },
      "search" => {
        "lines" => {
          "l1" => "D",
          "l2" => "#{legislative_term}/#{reference}"
        },
        "serverrecordname" => "dokument"
      }
    }
    mp = m.post(SEARCH_URL + '/parlis/browse.tt.json', hashbody.to_json, 'Content-Type' => 'application/json')
    data = JSON.parse(mp.body)
    return nil if data['fetched_hits'] <= 0
    rep_id = data["report_id"]
    SEARCH_URL + "/parlis/report.tt.html?report_id=#{rep_id}"
  end

  def self.get_detail_link(page)
    page.at_css('.fundstellenLinks')
  end

  def self.get_detail_originators(page)
    page.at_css('.drucksache-liste-urheber')
  end

  def self.link_is_answer?(originators)
    !originators.text.strip.match(/und\s+Antw/).nil?
  end

  def self.extract_doctype(match_result)
    case match_result.downcase
    when 'klanfr', 'klanf', 'kleine anfrage'
      Paper::DOCTYPE_MINOR_INTERPELLATION
    when 'granfr', 'granf', 'große anfrage', 'Große Anfrage'
      Paper::DOCTYPE_MAJOR_INTERPELLATION
    end
  end

  def self.extract_detail_title(page)
    page.at('.drucksache-liste-betreff').text.strip
  end

  def self.extract_from_originators(originators_line)
    match_result = originators_line.lstrip.match(/(Kleine Anfrage?|Große Anfrage?)\s+(.+?)\s+?([\d\.\s]+)?\s+(?:und\s+Antwort)\s+(.+)/m)
    return nil if match_result.nil?
    doctype = extract_doctype(match_result[1])
    names = match_result[2].gsub(/\s+(?:u.a.|u.u.)/, '').strip
    originators = NamePartyExtractor.new(names, NamePartyExtractor::NAME_BRACKET_PARTY).extract
    ministries = [match_result[4].strip]

    answerers = nil
    answerers = { ministries: ministries } unless ministries.blank?
    {
      doctype: doctype,
      published_at: Date.parse(match_result[3]),
      originators: originators,
      answerers: answerers
    }
  end

  def self.extract_meta(page)
    originators_text = get_detail_originators(page).text
    ometa = extract_from_originators(originators_text)
    link_text = get_detail_link(page).text
    full_reference = link_text.lstrip.match(/Drucksache\s+(\d+\/\d+).\s+([\d\.\s]+)/m)[1]
    return nil if full_reference.nil?
    {
      full_reference: full_reference,
      doctype: ometa[:doctype],
      published_at: ometa[:published_at],
      originators: ometa[:originators],
      answerers: ometa[:answerers]
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
      # url is nil, because it may not be answered yet
      published_at: meta[:published_at],
      # originator: people is set in detail scraper
      originators: { people: [], parties: [meta[:originator_party]] },
      # answerers is set in detail scraper
      # is_answer is set in detail scraper
      source_url: get_detail_url(legislative_term, reference)
    }
  end

  def self.extract_detail_paper(page)
    link = get_detail_link(page)
    fail "Can't extract detail link from Paper [BW ?]" if link.nil?

    title = extract_detail_title(page)
    url = link.attributes['href'].value

    originators = get_detail_originators(page)
    meta = extract_meta(page)
    fail "Can't extract detail meta data from Paper [BW ?] text: #{originators.text}" if meta.nil?

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
      is_answer: link_is_answer?(originators),
      originators: meta[:originators],
      answerers: meta[:answerers],
      source_url: get_detail_url(legislative_term, reference)
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
      report_url = BadenWuerttembergLandtagScraper.get_report_url(m, @legislative_term, @reference)
      fail 'Report not found' if report_url.nil?
      page = m.get report_url
      # fix missing encoding on report pages:
      page.encoding = 'utf-8'
      BadenWuerttembergLandtagScraper.extract_detail_paper(page)
    end
  end
end
