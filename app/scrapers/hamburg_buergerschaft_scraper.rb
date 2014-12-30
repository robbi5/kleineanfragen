require 'date'

module HamburgBuergerschaftScraper
  BASE_URL = 'https://www.buergerschaft-hh.de/'

  class Overview < Scraper
    # SEARCH_URL = BASE_URL + '/starweb/LTBB/servlet.starweb?path=LTBB/lisshfl.web&id=ltbbfastlink&search=WP%3d5+AND+%28DTYP%3dKleine+Anfrage%29&format=WEBVORGLFL'
    SEARCH_URL = BASE_URL + '/starweb/LTBB/servlet.starweb?path=LTBB/lisshfl.web&id=LTBBFASTLINK&format=WEBVORGLFL&search='
    # http://www.parldok.brandenburg.de/starweb/LTBB/servlet.starweb?path=LTBB/lisshfl.web&id=LTBBFASTLINK&search=TODAY%3dX+AND+WP%3d6+AND+%28DTYP%3dKleine+Anfrage%29&format=WEB2PDF

    def scrape
      papers = []

      fail 'fixme'
      # FIXME

      body.css('?').each do |item|
        # originators = NamePartyExtractor.new(_).extract
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

  class Detail < Scraper
    SEARCH_URL = BASE_URL + '/parldok/tcl/WPParse.tcl?template=ViewTrefferZahl.htm&ref_template=formdokumentnummer&DokumentenartID=1'
    # https://www.buergerschaft-hh.de/parldok/tcl/WPParse.tcl?c=14245810310297188579243&template=ViewTrefferZahl.htm&ref_template=formdokumentnummer&DokumentenartID=1&LegislaturperiodenNummer=20&Dokumentennummer=13764

    def initialize(legislative_term, reference)
      @legislative_term = legislative_term
      @reference = reference
    end

    def full_reference
      @legislative_term.to_s + '/' + @reference.to_s
    end

    def scrape
      mp = mechanize.get(SEARCH_URL + "&LegislaturperiodenNummer=#{@legislative_term}&Dokumentennummer=#{@reference}")

      body = mp.root.at_css('#parldokresult')
      title = body.at_css("td[headers='pd_titel']").text.strip
      url = body.at_css("td[headers='pd_titel'] a").attributes['href'].value
      full_reference = body.at_css("td[headers='pd_nummer']").text.strip
      date = body.at_css("td[headers='pd_datum']").text.strip
      names = body.at_css("td[headers='pd_urheber']").text.strip
      originators = NamePartyExtractor.new(names).extract

      url = Addressable::URI.parse(BASE_URL + path).normalize.to_s
      {
        legislative_term: @legislative_term,
        full_reference: full_reference,
        reference: @reference,
        title: title,
        published_at: Date.parse(date),
        url: url,
        originators: originators
      }
    end
  end
end