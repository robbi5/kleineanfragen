require 'mechanize'
require 'date'

module BrandenburgLandtagScraper
  BASE_URL = 'http://www.parldok.brandenburg.de'

  class Overview
    #SEARCH_URL = BASE_URL + '/starweb/LTBB/servlet.starweb?path=LTBB/lisshfl.web&id=ltbbfastlink&search=WP%3d5+AND+%28DTYP%3dKleine+Anfrage%29&format=WEBVORGLFL'
    SEARCH_URL = BASE_URL + '/starweb/LTBB/servlet.starweb?path=LTBB/lisshfl.web&id=LTBBFASTLINK&search=TODAY%3dX+AND+WP%3d5+AND+%28DTYP%3dKleine+Anfrage%29&format=WEBVORGLFL'

    def scrape
      m = Mechanize.new
      mp = m.get SEARCH_URL

      body = mp.search "//div[contains(@name, 'IfReportGenerated')]"
      legterm = body.search("//th[contains(@class, 'gross2')]").inner_html.strip
      legislative_term = legterm.match(/(\d+). Wahlperiode/)[1]
      papers = []

      body.css('>table').each do |item|
        link = item.at_css("a[href*='parladoku']")
        next if link.nil?

        titleEl = item.at(".//th/../following-sibling::tr[1]/td[2]")
        title = titleEl.text

        row = link.previous.text
        data = row.strip.match(/(.+) \((.+)\)\s+([\d\.]+) Drs$/)
        path = link.attributes["href"].value
        full_reference = link.text
        originators = {people: data[1], party: data[2]}
        date = data[3]
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
#   puts BrandenburgLandtagScraper::Overview.new.scrape.inspect
###