require 'mechanize'
require 'date'

module BayernLandtagScraper
  BASE_URL = 'http://www1.bayern.landtag.de'

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/webangebot1/dokumente.suche.maske.jsp?DOKUMENT_TYPE=EXTENDED&STATE=SHOW_MASK'

    def supports_pagination?
      true
    end

    def scrape(page = 1)
      mp = search(page)
      extract(mp)
    end

    def scrape_all
      page = 1
      papers = []
      loop do
        has_next_page = false
        mp = search(page)
        Rails.logger.debug "[scrape_all] page: #{page}"
        papers.concat extract(mp)
        if mp.search('//div[contains(@class, "cbox_content")]//a[contains(text(), "nächste Treffer")]').size > 0
          page += 1
          has_next_page = true
        end
        break unless has_next_page
      end
      Rails.logger.debug "[scrape_all] done extracting, #{papers.size} papers"
      papers
    end

    def search(page)
      m = mechanize
      mp = m.get SEARCH_URL
      search_form = mp.form 'suche'
      search_form.field_with(name: 'DOKUMENT_INTEGER_WAHLPERIODE').value = @legislative_term
      search_form.field_with(name: 'DOKUMENT_VORGANGSART').options.find { |opt| opt.text.include? 'Schriftliche Anfrage' }.select
      search_form.field_with(name: 'DOKUMENT_INTEGER_TREFFERANZAHL').value = @per_page
      search_form.add_field!('DOKUMENT_INTEGER_RESULT_START_INDEX', @per_page * (page - 1)) if page > 1
      submit_button = search_form.submits.find { |btn| btn.value == 'Suche starten' }
      m.submit(search_form, submit_button)
    end

    def extract(mp)
      papers = []
      i = 0
      mp.search('//table[not(contains(@class, "marg_"))]//tr[not(contains(@class, "clr_listhead"))]/td/b').each do |item|
        meta_element = item
        row = item.parent.parent

        full_reference = meta_element.text.match(/Nr. ([\d\/]+)/)[1]
        reference = full_reference.split('/').last
        published_at = Date.parse(meta_element.text.match(/([\d\.]+)$/)[1])

        Rails.logger.debug "[extract] item #{i += 1}: #{full_reference}"

        link_el = row.at_css('a')
        next if warn_broken(link_el.nil?, 'link_el not found', item)

        url = Addressable::URI.parse(BASE_URL + link_el.attributes['href'].value).normalize.to_s

        title_el = row.next_element.next_element.search('./td[3]')
        next if warn_broken(title_el.nil?, 'title_el not found', item)

        title = title_el.text.gsub(/\s+/, ' ').strip.gsub(/\n/, '-').gsub('... [mehr]', '').gsub('[weniger]', '').strip

        papers << {
          legislative_term: @legislative_term,
          full_reference: full_reference,
          reference: reference,
          published_at: published_at,
          url: url,
          title: title
        }
      end

      warn_broken(papers.size != @per_page, "Got only #{papers.size} of #{@per_page} papers")

      papers
    end
  end

  class Detail < Scraper
    SEARCH_URL = BASE_URL + '/webangebot1/dokumente.suche.maske.jsp?STATE=SHOW_MASK&BUTTONSCHLAGWORT=Suche+starten&DOKUMENT_DOKUMENTNR='

    def initialize(legislative_term, reference)
      @legislative_term = legislative_term
      @reference = reference
    end

    def full_reference
      @legislative_term.to_s + '/' + @reference.to_s
    end

    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape(full_reference)
      mp = mp.link_with(href: /\#LASTFOLDER$/).click
      table = mp.search('//div/table//table[1]').first
      data = mp.search('//div/table//table[1]//td[2]').first

      title_el = table.parent.parent.previous_element.search('./td[3]')
      title = title_el.text.gsub(/\s+/, ' ').strip.gsub(/\n/, '-').gsub('... [mehr]', '').gsub('[weniger]', '').strip

      party = data.inner_html.strip
      {
        legislative_term: @legislative_term,
        full_reference: full_reference,
        reference: @reference,
        title: title,
        # published_at: published_at, # FIXME
        # url: url, # FIXME
        originators: { parties: [party] }
      }
    end
  end
end

###
# Usage:
#   puts BayernLandtagScraper::Overview.new.scrape.inspect
#   puts BayernLandtagScraper::Detail.new(17, 2000).scrape.inspect
###