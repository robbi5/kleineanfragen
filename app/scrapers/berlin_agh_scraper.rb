require 'date'

module BerlinAghScraper
  BASE_URL = 'http://pardok.parlament-berlin.de'

  class Overview < Scraper
    SEARCH_URL = BASE_URL + '/starweb/AHAB/servlet.starweb?path=AHAB/lisshfl.web&id=ahabfastlink&format=WEBVORGLFL&search='

    # FIXME: find search with pagination, add support for pagination
    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape("WP=#{@legislative_term} AND (etyp=schriftl*)")

      body = mp.search "//table[contains(@summary, 'Hauptbereich')]"
      legterm = body.search("//th[contains(@class, 'gross2')]").inner_html.strip
      legislative_term = legterm.match(/(\d+). Wahlperiode/)[1]
      warn_broken(legislative_term.to_i != @legislative_term, 'legislative_term not correct', legislative_term)
      papers = []

      body.search('//td[contains(@colspan, 3)]').each do |item|
        title_el = item.search('../following-sibling::tr[1]/td[2]/b')
        next if title_el.length == 0
        title = title_el.text.gsub("\n", ' ')
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
        ministries = []
        ministry_line = container.search('a')[1].try(:previous_element).try(:previous).try(:text)
        if ministry_line
          ministry = Ministry.where(short_name: ministry_line.strip).first
          ministries << ministry if ministry
        end

        url = Addressable::URI.parse(BASE_URL + path).normalize.to_s

        papers << {
          legislative_term: @legislative_term,
          full_reference: full_reference,
          reference: reference,
          title: title,
          url: url,
          published_at: published_at,
          originators: originators,
          answerers: { ministries: ministries }
        }
      end

      papers
    end
  end

  class Detail < DetailScraper
    SEARCH_URL = BASE_URL + '/starweb/AHAB/servlet.starweb?path=AHAB/lisshfl.web&id=ahabfastlink&format=WEBVORGLFL&search='

    def scrape
      mp = mechanize.get SEARCH_URL + CGI.escape('WP=' + @legislative_term.to_s + ' AND DNR=' + @reference.to_s)
      body = mp.search "//table[contains(@summary, 'Hauptbereich')]"
      item = body.search('//td[contains(@colspan, 3)]')
      title_el = item.search('../following-sibling::tr[1]/td[2]/b')
      title = title_el.text.gsub("\n", ' ')

      container = item.search('../following-sibling::tr[4]/td[2]')
      # FIXME duplicate code, cleanup!
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
        fail 'link_el not found'
      end

      names = link.previous_element.previous.text
      originators = NamePartyExtractor.new(names).extract
      path = link.attributes['href'].value
      full_reference = link.text.match(/([\d\/]+)/)[1]
      date = container.text.match(/.*vom ([\d\.]+)/m)[1]
      published_at = Date.parse(date)
      ministries = []
      ministry_line = container.search('a')[1].try(:previous_element).try(:previous).try(:text)
      if ministry_line
        ministry = Ministry.where(short_name: ministry_line.strip).first
        ministries << ministry if ministry
      end

      url = Addressable::URI.parse(BASE_URL + path).normalize.to_s

      {
        legislative_term: @legislative_term,
        full_reference: full_reference,
        reference: @reference,
        title: title,
        url: url,
        published_at: published_at,
        originators: originators,
        answerers: { ministries: ministries }
      }
    end
  end
end

###
# Usage:
#   puts BerlinAghScraper::Overview.new.scrape.inspect
#   puts BerlinAghScraper::Detail.new(17, 2000).scrape.inspect
###