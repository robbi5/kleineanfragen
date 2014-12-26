require 'date'

module BerlinAghScraper
  BASE_URL = 'http://pardok.parlament-berlin.de'

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/AHAB/servlet.starweb?path=AHAB/lisshfl.web&id=ahabfastlink&format=WEBVORGLFL&search='

    # FIXME: add support for pagination
    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape('WP=' + @legislative_term + ' AND (etyp=schriftl*)')

      body = mp.search "//table[contains(@summary, 'Hauptbereich')]"
      legterm = body.search("//th[contains(@class, 'gross2')]").inner_html.strip
      legislative_term = legterm.match(/(\d+). Wahlperiode/)[1]
      # WARN if legislative_term.to_i != @legislative_term
      papers = []

      body.search('//td[contains(@colspan, 3)]').each do |item|
        title_el = item.search('../following-sibling::tr[1]/td[2]/b')
        next if title_el.length == 0
        title = title_el.inner_html.gsub(/\<br\>/, ' ')
        container = item.search('../following-sibling::tr[4]/td[2]')

        # we hit the subtitle row
        if container.search('a').length == 0
          container = item.search('../following-sibling::tr[5]/td[2]')

          # and now the location row
          if container.search('a').length == 0
            container = item.search('../following-sibling::tr[6]/td[2]')
          end
        end

        # the first "Drucksache 17/1234" link
        link = container.search('a')[0]

        if link.nil? || container.search('a').length == 0
          # skip broken records (no pdf)
          warn_broken(true, 'link_el not found', item)
          next
        end

        names = link.previous_element.previous.text
        originators = NamePartyExtractor.new(names).extract
        path = link.attributes['href'].value
        full_reference = link.text.match(/([\d\/]+)/)[1]
        reference = full_reference.split('/').last
        date = container.text.match(/.*vom ([\d\.]+)/m)[1]
        published_at = Date.parse(date)

        url =  Addressable::URI.parse(BASE_URL + path).normalize.to_s

        papers << {
          legislative_term: @legislative_term,
          full_reference: full_reference,
          reference: reference,
          title: title,
          url: url,
          published_at: published_at,
          originators: originators
        }
      end

      papers
    end
  end
end

###
# Usage:
#   puts BerlinAghScraper::Overview.new.scrape.inspect
###