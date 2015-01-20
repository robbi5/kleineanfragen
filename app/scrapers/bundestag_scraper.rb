require 'date'

module BundestagScraper
  BASE_URL = 'http://dipbt.bundestag.de'

  class Overview < Scraper
    # http://dipbt.bundestag.de/extrakt/ba/WP#{@legislative_term}/
    OVERVIEW_URL = BASE_URL + '/extrakt/ba'

    TYPES = ['Kleine Anfrage', 'Große Anfrage']

    def scrape
      m = mechanize
      mp = m.get "#{OVERVIEW_URL}/WP#{@legislative_term}/"
      table = mp.search "//table[contains(@summary, 'Beratungsabläufe')]"

      papers = []
      table.css('tbody tr').each do |row|
        type = row.css('td')[0].text
        link = row.at_css('td a')
        date = row.css('td')[2].text
        detail_url = link.attributes['href'].value

        next unless TYPES.include?(type)

        page = m.get "#{OVERVIEW_URL}/WP#{@legislative_term}/#{detail_url}"
        comment_start = page.content.index '<?xml'
        comment_end = page.content.index('-->', comment_start)
        xml = page.content[comment_start...comment_end]
        xml = xml.strip.gsub(/<-.*->/, '') # remove nested "comments"

        doc = Nokogiri.parse xml
        status = doc.at_css('VORGANG AKTUELLER_STAND').text

        unless status == 'Beantwortet'
          Rails.logger.info "#{detail_url}: ignored, status: #{status}"
          next
        end

        title = doc.at_css('VORGANG TITEL').text.strip
        legislative_term = doc.at_css('VORGANG WAHLPERIODE').text.to_i

        url = nil
        full_reference = ''
        found = false
        doc.css('WICHTIGE_DRUCKSACHE').each do |node|
          next unless node.at_css('DRS_TYP').text == 'Antwort'
          found = true
          url = node.at_css('DRS_LINK').try(:text)
          full_reference = node.at_css('DRS_NUMMER').text
        end

        unless found && !url.blank?
          Rails.logger.info "#{detail_url}: ignored, no paper found"
          next
        end

        reference = full_reference.split('/').last

        url = Addressable::URI.parse(url).normalize.to_s

        originators = { people: [], parties: [] }
        answerers = { ministries: [] }
        doc.css('VORGANGSABLAUF VORGANGSPOSITION').each do |node|
          urheber = node.at_css('URHEBER').text
          if urheber.starts_with? 'Kleine Anfrage'
            node.css('PERSOENLICHER_URHEBER').each do |unode|
              originators[:people] << "#{unode.at_css('VORNAME').text} #{unode.at_css('NACHNAME').text}"
              party = unode.at_css('FRAKTION').text
              originators[:parties] << party unless originators[:parties].include? party
            end
          elsif urheber.starts_with? 'Antwort'
            _, ministry = urheber.match(/: ([^(]*)/).to_a
            if !ministry.nil?
              ministry = ministry.strip.sub(/^Bundesregierung, /, '')
              answerers[:ministries] << ministry
            else
              Rails.logger.info "#{full_reference}: no ministry found"
            end
            # got date already on overview page, else it could be in FUNDSTELLE
          end
        end

        published_at = Date.parse(date)

        papers << {
          legislative_term: legislative_term,
          full_reference: full_reference,
          reference: reference,
          title: title,
          url: url,
          published_at: published_at,
          originators: originators,
          answerers: answerers
        }
      end

      papers
    end
  end
end