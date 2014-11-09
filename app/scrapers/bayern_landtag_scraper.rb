require 'mechanize'
require 'date'

module BayernLandtagScraper
  BASE_URL = 'http://www1.bayern.landtag.de'

  class Overview
    SEARCH_URL = BASE_URL + '/webangebot1/dokumente.suche.maske.jsp?DOKUMENT_TYPE=EXTENDED&STATE=SHOW_MASK'

    def initialize
      @per_page = 50
    end

    def scrape(page = 1)
      m = Mechanize.new
      mp = m.get SEARCH_URL
      search_form = mp.form 'suche'
      legislative_term = search_form.field_with(name: 'DOKUMENT_INTEGER_WAHLPERIODE').value
      search_form.field_with(name: 'DOKUMENT_VORGANGSART').options.find { |opt| opt.text.include? "Schriftliche Anfrage" }.select
      search_form.field_with(name: 'DOKUMENT_INTEGER_TREFFERANZAHL').value = @per_page
      search_form.add_field!('DOKUMENT_INTEGER_RESULT_START_INDEX', @per_page * (page - 1)) if page > 1
      submit_button = search_form.submits.find { |btn| btn.value == 'Suche starten' }
      mp = m.submit(search_form, submit_button)

      papers = []
      mp.search('//table[not(contains(@class, "marg_"))]//tr[not(contains(@class, "clr_listhead"))]/td/b').each do |item|
        meta_element = item
        row = item.parent.parent

        full_reference = meta_element.text.match(/Nr. ([\d\/]+)/)[1]
        reference = full_reference.split('/').last
        published_at = Date.parse(meta_element.text.match(/([\d\.]+)$/)[1])

        link_el = row.at_css('a')
        next if warn_broken(link_el.nil?, 'link_el not found', item)

        url = Addressable::URI.parse(BASE_URL + link_el.attributes["href"].value).normalize.to_s

        title_el = row.next_element.next_element.search('./td[3]')
        next if warn_broken(title_el.nil?, 'title_el not found', item)

        title = title_el.text.gsub(/\s+/, ' ').strip.gsub(/\n/, '-').gsub('... [mehr]', '').gsub('[weniger]', '').strip

        papers << {
          :legislative_term => legislative_term,
          :full_reference => full_reference,
          :reference => reference,
          :published_at => published_at,
          :url => url,
          :title => title
        }
      end

      warn_broken(papers.size != @per_page, "Got only #{papers.size} of #{@per_page} papers")

      papers
    end

    def warn_broken(bool, reason, item = nil)
      return false if !bool
      Rails.logger.warn reason
      Rails.logger.debug { item.to_s.gsub(/\n|\s\s+/, "") } unless item.nil?
      true
    end
  end

  class Detail
    SEARCH_URL = BASE_URL + '/webangebot1/dokumente.suche.maske.jsp?STATE=SHOW_MASK&BUTTONSCHLAGWORT=Suche+starten&DOKUMENT_DOKUMENTNR='

    def initialize(legislative_term, reference)
      @legislative_term = legislative_term
      @reference = reference
    end

    def full_reference
      @legislative_term.to_s + '/' + @reference.to_s
    end

    def scrape
      m = Mechanize.new
      mp = m.get SEARCH_URL + CGI.escape(full_reference)
      mp = mp.link_with(href: /\#LASTFOLDER$/).click
      data = mp.search '//div/table//table[1]//td[2]'

      originator = data[0].inner_html.strip

      {originator: originator}
    end
  end
end

###
# Usage:
#   puts BayernLandtagScraper::Overview.new.scrape.inspect
#   puts BayernLandtagScraper::Detail.new(17, 2000).scrape.inspect
###

