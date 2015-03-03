require 'date'

module BrandenburgLandtagScraper
  BASE_URL = 'http://www.parldok.brandenburg.de'

  # TODO: Parse and use RSS?
  # http://www.parldok.brandenburg.de/starweb/LTBBRSS/servlet.starweb?path=LTBBRSS/LTBBProfilRSS.web&format=DokumentUP&search=%28%28%2fWP+6%29+AND+%28%2fDART%2cDARTS%2cETYPF%2cETYP2F%2cDTYPF%2cDTYP2F+%28%22KLEINE+ANFRAGE%22+OR+%22GRO%DFE+ANFRAGE%22%29%29+AND+TYP%3dDOKDBE%29&title=Anfragen&x=x.xml
  # -> ((/WP 6) AND (/DART,DARTS,ETYPF,ETYP2F,DTYPF,DTYP2F ("KLEINE ANFRAGE" OR "GROßE ANFRAGE")) AND TYP=DOKDBE)
  # Nope, no pagination

  class Overview < Scraper
    # SEARCH_URL = BASE_URL + '/starweb/LTBB/servlet.starweb?path=LTBB/lisshfl.web&id=ltbbfastlink&search=WP%3d5+AND+%28DTYP%3dKleine+Anfrage%29&format=WEBVORGLFL'
    SEARCH_URL = BASE_URL + '/starweb/LTBB/servlet.starweb?path=LTBB/lisshfl.web&id=LTBBFASTLINK&format=WEBVORGLFL&search='

    def scrape
      # FIXME: today?!, pagination?
      mp = mechanize.get SEARCH_URL + CGI.escape('TODAY=X AND WP=' + @legislative_term + ' AND (DTYP=Kleine Anfrage)')
      body = mp.search "//table[contains(@summary, 'Hauptbereich')]"

      papers = []
      body.css('table td.klein').each do |item|
        title_el = item.parent.next_element.next_element
        title = title_el.text

        data_el = title_el.next_element.at_css('table td+td')
        link = data_el.at_css('a')
        path = link.attributes['href'].value
        url = Addressable::URI.parse(BASE_URL + path).normalize.to_s
        full_reference = link.text
        reference = full_reference.split('/').last
        # KlAnfr 123 Aaaaaa Bbbbbb (ABC), Cccccc Ddddddd (ABC) 11.12.2014 Drs 6/123 (1 S.)
        meta = data_el.text.strip.match(/\s(\D+ \(.+\),?)\s+([\d\.]+) Drs/)
        originators = NamePartyExtractor.new(meta[1]).extract
        date = meta[2]
        published_at = Date.parse(date)
        papers << {
          legislative_term: @legislative_term,
          full_reference: full_reference,
          doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
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

  class Detail < DetailScraper
    # using rss/xml export
    SEARCH_URL = BASE_URL + '/starweb/LTBBRSS/servlet.starweb?path=LTBBRSS/LTBBProfilRSS.web&format=DokumentUP&search='

    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape('DART=D AND WP=' + @legislative_term + ' AND DNR,KORD=' + @reference)
      title = mp.search('//title').first.text
      desc = mp.search('//description').first.text
      # Kleine Anfrage 123 Aaaaaaaa Bbbbbbbb (Ccccc) Drucksache 1/222 10.11.2014 (2 S.)
      _, person, party, date = title.match(/\d+\s(\D+)\s\((.*)\)\s.*\s([\d\.]+)\s/).to_a
      _, path = desc.match(/\shref="(.*)"\s/).to_a
      url = Addressable::URI.parse(BASE_URL + path).normalize.to_s
      {
        legislative_term: @legislative_term,
        full_reference: full_reference,
        reference: @reference,
        title: title,
        published_at: Date.parse(date),
        url: url,
        originators: { people: [person], parties: [party] }
      }
    end
  end
end

###
# Usage:
#   puts BrandenburgLandtagScraper::Overview.new.scrape.inspect
###