require 'date'

#
# Saarland is based on SharePoint. (No idea why anyone thinks thats a sane idea)
#
# Get Version: https://www.landtag-saar.de/_vti_pvt/service.cnf
# # vti_extenderversion:SR|15.0.0.4797
#
# An request to https://www.landtag-saar.de/_vti_bin/ brings us the following header:
# # MicrosoftSharePointTeamServices:15.0.0.4569
#
# So it is an SharePoint 2013.
# But all the interesting endpoints (/_api, /_vti_bin/listdata.svc/) are locked down.
# Sad :(
#
# Update 2017-01-10: They had the clever idea to pack the data as json into one big
# hidden input field.
#
module SaarlandScraper
  BASE_URL = 'https://www.landtag-saar.de'
  OVERVIEW_URL = BASE_URL + '/dokumente/drucksachen'

  class Detail < DetailScraper
    def scrape
      mp = mechanize.get OVERVIEW_URL
      entry = SaarlandScraper.extract_entries(mp).find { |e| e['Dokumentnummer'].strip == full_reference }
      return nil if entry.nil?
      SaarlandScraper.extract_paper(entry)
    end
  end

  class Overview < Scraper
    def supports_streaming?
      true
    end

    def scrape(&block)
      @m ||= mechanize
      papers = []
      streaming = block_given?
      mp = @m.get OVERVIEW_URL
      SaarlandScraper.extract_entries(mp).each do |entry|
        begin
          paper = SaarlandScraper.extract_paper(entry)
        rescue => e
          logger.warn e
          next
        end
        next if paper.nil?
        if streaming
          yield paper
        else
          papers << paper
        end
      end
      papers unless streaming
    end
  end

  def self.extract_entries(mp)
    v = mp.search('//input[@type="hidden"]')
      .find { |i| i.attributes['name'].to_s.ends_with? '$documentListInput' }
      .attributes['value']
    v = v.to_s.gsub(/\&qu?o?t?quot;/, '"')
    JSON.parse(v)
  end

  def self.extract_doc_link(entry)
    Addressable::URI.parse(BASE_URL).join(entry['URL']).normalize.to_s
  end

  def self.extract_date(entry)
    Date.parse(entry['Dokumentdatum'])
  end

  def self.extract_title(entry)
    entry['Titel'].strip
  end

  def self.extract_paper(entry)
    return nil if entry.nil? || !extract_is_answer(entry)
    url = extract_doc_link(entry)
    full_reference = entry['Dokumentnummer']
    reference = full_reference.split('/').last
    legislative_term = full_reference.split('/').first
    title = extract_title(entry)
    published_at = extract_date(entry)

    {
      legislative_term: legislative_term,
      full_reference: full_reference,
      reference: reference,
      doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
      title: title,
      url: url,
      published_at: published_at,
      # originators unknown in overview
      is_answer: true,
      answerers: { ministries: ['Landesregierung'] }
    }
  end

  def self.extract_is_answer(entry)
    entry['Dokumentname'].starts_with? 'Aw'
  end
end