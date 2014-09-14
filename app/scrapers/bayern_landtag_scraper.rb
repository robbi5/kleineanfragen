require 'wombat'
require 'mechanize'
require 'date'

module BayernLandtagScraper
  BASE_URL = 'http://www1.bayern.landtag.de'

  class Overview
    include Wombat::Crawler

    SEARCH_URL = BASE_URL + '/webangebot1/dokumente.suche.maske.jsp?DOKUMENT_TYPE=EXTENDED&STATE=SHOW_MASK'

    # override with filter function, because the xpaths still return broken records
    def scrape
      res = crawl
      res["papers"].select{ |item| !item["url"].nil? && !item["title"].nil? && !item["full_reference"].nil? }
    end

    m = Mechanize.new
    mp = m.get SEARCH_URL
    search_form = mp.form 'suche'
    legislative_term = search_form.field_with(name: 'DOKUMENT_INTEGER_WAHLPERIODE').value
    search_form.field_with(name: 'DOKUMENT_VORGANGSART').options.find { |opt| opt.text.include? "Schriftliche Anfrage" }.select
    search_form.field_with(name: 'DOKUMENT_INTEGER_TREFFERANZAHL').value = 50
    submit_button = search_form.submits.find { |btn| btn.value == 'Suche starten' }
    mp = m.submit(search_form, submit_button)

    # wombat: use mechanized page
    page mp

    #debug mp.inspect

    papers 'xpath=//table[not(contains(@class, "marg_"))]//tr[not(contains(@class, "clr_listhead"))]', :iterator do
      #title 'css=b'
      legislative_term legislative_term
      full_reference 'css=b' do |text|
        text.match(/Nr. ([\d\/]+)/)[1] unless text.nil?
      end
      published_at 'css=b' do |text|
        Date.parse(text.match(/([\d\.]+)$/)[1]) unless text.nil?
      end
      url 'xpath=.//a[not(contains(@href, "LASTFOLDER"))]/@href' do |href|
        BASE_URL + href unless href.nil?
      end
      #text 'xpath=(following-sibling::tr[2]/td[contains(@class, "pad_bot0")])[1]'
      title 'xpath=following-sibling::tr[2]/td[3]' do |text|
        text.gsub(/\s+/, ' ').strip.gsub(/\n/, '-').strip unless text.nil?
      end
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

    # doesn't use wombat, mechanize is just fine
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

