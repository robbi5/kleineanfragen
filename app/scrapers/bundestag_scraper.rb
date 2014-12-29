require 'date'

# TODO: look into offenesparlament: scrape.py
# http://dipbt.bundestag.de/extrakt/ba/WP#{@legislative_term}/

module BundestagScraper
  BASE_URL = 'http://dipbt.bundestag.de'
  START_URL = BASE_URL + '/dip21.web/bt'
  SEARCH_URL = BASE_URL + '/dip21.web/searchProcedures.do'

  class Overview < Scraper
    def scrape
      m = mechanize
      # need to open start page first, it sets some required session cookies
      m.get START_URL
      # then we can access the search
      mp = m.get SEARCH_URL

      search_form = mp.forms[0]
      search_form.field_with(name: 'vorgangstyp').options.find { |opt| opt.text.include? 'Kleine Anfrage' }.select
      submit_button = search_form.submits.find { |btn| btn.value == 'Suchen' }
      mp = m.submit(search_form, submit_button)

      papers = []
      i = 0

      mp.root.css("table[summary='Ergebnisliste'] tbody tr").each do |row|
        i += 1
        next if i < 40 # DEBUG
        break if i > 60 # DEBUG
        link = row.at('.//td[3]/a')
        # url = link.attributes['href'].value
        acronym = row.at('.//td[3]//acronym')
        if !acronym.nil?
          title = acronym.attributes['title'].value
        else
          title = link.text
        end
        date = row.at('.//td[4]').text
        published_at = Date.parse(date)

        puts "+ #{title}"

        originators = []
        full_reference = nil
        url = nil

        page = m.click link
        comment_start = page.content.index '<?xml'
        comment_end = page.content.index('-->', comment_start)
        xml = page.content[comment_start...comment_end]
        xml = xml.strip.gsub(/<-.*->/, '') # remove nested "comments"

        # puts xml
        doc = Nokogiri.parse xml
        legislative_term = doc.css('VORGANG WAHLPERIODE').text.to_i
        status = doc.css('VORGANG AKTUELLER_STAND').text
        unless (originator = doc.css('VORGANG INITIATIVE')).empty?
          originators << originator.text
        end

        # skip if no documents are available
        next if doc.css('VORGANG WICHTIGE_DRUCKSACHE').empty?

        doc.css('VORGANG WICHTIGE_DRUCKSACHE').each do |drs|
          art = drs.css('DRS_TYP').text
          next if art == 'Kleine Anfrage'
          url = drs.css('DRS_LINK').text
          full_reference = drs.css('DRS_NUMMER').text
        end

        puts "  Status: #{status}"
        puts "  URL: #{url}"

        next if status == 'Noch nicht beantwortet'
        next if full_reference.blank?

        if status == 'Beantwortet'
          first = doc.css('VORGANG WICHTIGE_DRUCKSACHE')
          if first.length == 1 && first.css('DRS_TYP').text == 'Kleine Anfrage'
            puts '  ⚠️  Nur Anfrage, keine Antwort'
            next
          end
          if url.blank? && !full_reference.blank?
            puts '  ⚠️  Antwort vorhanden aber nicht veröffentlicht'
            next
          end
        end

        # FIXME: add incomplete papers to "watchlist"

        # last resort
        next if url.blank?

        reference = full_reference.split('/').last

        # puts xml
        papers << {
          legislative_term: legislative_term,
          full_reference: full_reference,
          reference: reference,
          title: title,
          url: url,
          published_at: published_at,
          originators: originators
        }
      end

      # FIXME: navigate to next page

      puts papers.inspect

      papers
    end
  end
end

###
# Usage:
#   puts BundestagScraper::Overview.new.scrape.inspect
###