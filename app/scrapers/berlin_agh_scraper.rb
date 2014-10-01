require 'mechanize'
require 'date'

module BerlinAghScraper
  BASE_URL = 'http://pardok.parlament-berlin.de'

  class Overview
    SEARCH_URL = BASE_URL + '/starweb/AHAB/servlet.starweb?path=AHAB/lisshfl.web&id=ahabfastlink&search=WP%3d17+AND+%28etyp%3dschriftl%2a%29&format=WEBVORGLFL'

    def scrape
      m = Mechanize.new
      mp = m.get SEARCH_URL

      body = mp.search "//table[contains(@summary, 'Hauptbereich')]"
      legterm = body.search("//th[contains(@class, 'gross2')]").inner_html.strip
      legislative_term = legterm.match(/(\d+). Wahlperiode/)[1]
      papers = []

      body.search('//td[contains(@colspan, 3)]').each do |item|
        titleEl = item.search('../following-sibling::tr[1]/td[2]/b')
        next if titleEl.length == 0
        title = titleEl.inner_html.gsub(/\<br\>/, ' ')
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
          next
        end

        originators = link.previous_element.previous.text
        path = link.attributes["href"].value
        full_reference = link.text.match(/([\d\/]+)/)[1]
        date = container.text.match(/.*vom ([\d\.]+)/m)[1]
        published_at = Date.parse(date)

        url =  Addressable::URI.parse(BASE_URL + path).normalize.to_s

        papers << {
          legislative_term: legislative_term,
          full_reference: full_reference,
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