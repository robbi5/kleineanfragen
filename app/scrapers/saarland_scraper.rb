require 'date'

module SaarlandScraper
  BASE_URL = 'http://www.landtag-saar.de'

  class Detail < DetailScraper
    def scrape
      text = SaarlandScraper.build_text_parameter(@legislative_term, @reference)
      parameters = "#{text}&r=saarlandcontenttype%3D%22drucksache%22%20saarlandwahlperiode%3D%22#{@legislative_term}%22"
      mp = mechanize.get "#{BASE_URL}/Service/Seiten/Suche.aspx?#{parameters}"
      entry = SaarlandScraper.extract_search_entry(mp, @legislative_term, @reference)
      SaarlandScraper.extract_paper_from_search_entry(entry, @legislative_term, @reference)
    end
  end

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/Dokumente/Seiten/Drucksachen.aspx?FilterField1=Wahlperiode&FilterValue1='

    def supports_streaming?
      true
    end

    def scrape(&block)
      @m ||= mechanize
      page = 1
      papers = []
      block = -> (paper) { papers << paper } unless block_given?
      mp = @m.get SEARCH_URL + "#{@legislative_term}%2E%20WP" if mp.nil?
      loop do
        logger.debug "[scrape] page: #{page}"
        scrape_page(mp, &block)
        next_page_img = mp.search('//td[@id="bottomPagingCellWPQ2"]//img[contains(@src, "next.gif")]')[0]
        break if next_page_img.nil?
        page += 1
        link_el = next_page_img.parent
        mp = @m.get SaarlandScraper.extract_next_link_url(link_el)
      end
      papers unless block_given?
    end

    def scrape_page(mp, &block)
      streaming = block_given?
      papers = []
      SaarlandScraper.extract_entries(mp).each do |entry|
        begin
          paper = SaarlandScraper.extract_paper(entry)
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
      papers unless streaming
    end
  end

  def self.extract_next_link_url(link_el)
    onclick = link_el.attributes['onclick'].value
    return nil if onclick.nil?
    rel_url = onclick.match(/"(.+)"/)[1].gsub(/\\u0026/, '&')
    Addressable::URI.parse(BASE_URL + rel_url).normalize.to_s
  end

  def self.extract_entries(mp)
    mp.search('//table[@class="ms-listviewtable"]//tr[(@class!="ms-viewheadertr ms-vhltr")]')
  end

  def self.extract_doc_link(entry)
    url = entry.at_css('a').attr('href')
    Addressable::URI.parse(BASE_URL + url).normalize.to_s
  end

  def self.extract_full_reference_from_href(href)
    href = href.split('/').last.split('.').first
    href.split('_')[0][2] + href.split('_')[0][3] + '/' + href.split('_')[1]
  end

  def self.extract_date(entry)
    Date.parse(entry.search('.//nobr').try(:text))
  end

  def self.extract_title(entry)
    entry.search('.//td[4]').try(:text)
  end

  def self.extract_paper(entry)
    href = extract_doc_link(entry)
    return if !extract_is_answer(href)
    full_reference = extract_full_reference_from_href(href)
    reference = full_reference.split('/').last
    legislative_term = full_reference.split('/').first
    title = extract_title(entry)
    published_at = extract_date(entry)
    originators = extract_parties(extract_originator_text(entry))

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
      reference: reference,
      title: title,
      url: href,
      published_at: published_at,
      originators: originators,
      is_answer: true
    }
  end

  def self.extract_is_answer(href)
    # check baseurl/path/to/doc/XX11_1234 for XX=Aw
    href = href.split('/').last.split('.').first
    'Aw' == (href[0..1])
  end

  def self.extract_parties(originator_text)
    { parties: NamePartyExtractor.new(originator_text).extract[:parties] }
  end

  def self.extract_originator_text(entry)
    entry.search('.//td[5]').try(:text)
  end

  # k=Aw14_0072
  def self.build_text_parameter(term, ref)
    "k=Aw#{term}_#{ref}"
  end

  def self.extract_search_entry(mp, term, ref)
    mp.search('//*[@id="CSR"]/div/p').map do |item|
      nil unless item.try(:text).include? "Aw#{term}_#{ref}"
      {
        title: item.previous_element.previous_element.css('a').attr('title').value,
        description: item.previous_element.text.split('…')[0].strip,
        url: item.text
      }
    end
  end

  def self.extract_paper_from_search_entry(entry, term, ref)
    description = entry[:description]
    url = entry[:url]
    title = entry[:title]
    published_date = Date.parse(/\d{2}\.\d{2}\.\d{4}/.match(description)[0])

    {
      legislative_term: term,
      full_reference: "#{term}/#{ref}",
      reference: ref,
      doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
      title: title,
      url: url,
      published_at: published_date,
      is_answer: true
    }
  end
end