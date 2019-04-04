require 'date'

module SaarlandScraper
  BASE_URL = 'https://www.landtag-saar.de'
  OVERVIEW_URL = BASE_URL + '/umbraco/aawSearchSurfaceController/SearchSurface/GetSearchResults/'

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
      mp = load_overview_page(@m)
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

    private

    def load_overview_page(mechanize_agent)
      headers = {"Accept" => "application/json, text/javascript, */*; q=0.01"}
      body = {
        "Filter" => {
          "Periods" => []
        },
        "Pageination" => {
          "Skip" => 0,
          "Take" => 100
        },
        "Sections" => {
          "Print" => true,
          "PlenaryProtocol" => false,
          "Law" => false,
          "PublicConsultation" => false
        },
        "Sort" => {
          "SortType" => 0,
          "SortValue" => 0
        },
        "OnlyTitle" => false,
        "Value" => "",
        "CurrentSearchTab" => 1,
        "KendoFilter" => nil
      }.to_json

      mechanize_agent.post(OVERVIEW_URL, body, headers).body
    end
  end

  def self.extract_entries(mp)
    JSON.parse(mp)["FilteredResult"]
  end

  def self.extract_doc_link(entry)
    Addressable::URI.parse(BASE_URL).join(entry['FilePath']).normalize.to_s
  end

  def self.extract_date(entry)
    dotnet_serialized_date = entry['PublicDate']
    seconds_since_epoch = dotnet_serialized_date.scan(/[0-9]+/)[0].to_i / 1000.0

    Time.at(seconds_since_epoch).utc.to_date
  end

  def self.extract_title(entry)
    entry['Title'].strip
  end

  def self.extract_paper(entry)
    return nil if entry.nil? || !extract_is_answer(entry)
    url = extract_doc_link(entry)
    full_reference = entry['DocumentNumber']
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
    entry['FileName'].starts_with? 'Aw'
  end
end
