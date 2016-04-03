require 'zip'

module SachsenExportScraper
  EXPORT_BASE = 'http://edas.landtag.sachsen.de/KlAnfrDe/'

  def self.create_export_url(date = nil)
    date = Date.current - 1 if date.nil? # yesterday
    EXPORT_BASE + export_filename(date) + ".zip"
  end

  def self.export_filename(date = nil)
    date = Date.current - 1 if date.nil? # yesterday
    "KlAnfrDe_#{date.iso8601}"
  end

  class Overview < Scraper
    def initialize(legislative_term, options = {})
      super(legislative_term)
      @options = { force: false }.merge(options)

      @export_url = @options[:url] || SachsenExportScraper.create_export_url
      @xml_filename = SachsenExportScraper.export_filename + '.xml'
      @zip_filename = 'SN-' + SachsenExportScraper.export_filename + '.zip'
    end

    def supports_streaming?
      true
    end

    def scrape(&block)
      download if !downloaded? || @options[:force]

      logger.info "Successfully downloaded to #{path}"

      extract
      read(&block)
    end

    def downloaded?
      File.exists?(path) && File.size?(path)
    end

    def path
      @zip_path ||= Rails.configuration.x.export_storage.join(@zip_filename).to_s
    end

    def download
      resp = self.class.patron_session.get(@export_url)
      fail "Download failed with status #{resp.status}. url=#{@export_url}" if resp.status != 200

      f = File.open(path, 'wb')
      begin
        f.write(resp.body)
      rescue
        fail "Cannot write file for export. path=#{@zip_path} url=#{@export_url}"
      ensure
        f.close if f
      end

      @zipfile = f
    end

    def extract
      @file = ::Zip::File.open(path).get_input_stream(@xml_filename)
    end

    def self.parser(file)
      Saxerator.parser(file) { |config| config.put_attributes_in_hash! }
    end

    def read(&block)
      self.class.read(@file, @legislative_term, logger, &block)
    end

    def self.read(file, legislative_term, logger = nil)
      parser(file).for_tag(:Vorgang).each do |item|
        begin
          paper = parse_item(item)
        rescue => e
          logger.debug item.inspect unless logger.nil?
          fail e
        end

        next if paper.nil?
        next if paper[:legislative_term] != legislative_term

        yield paper
      end
    end

    def self.vtyp_to_paper_type(vtyp)
      {
        'klanfr' => Paper::DOCTYPE_MINOR_INTERPELLATION,
        'granfr' => Paper::DOCTYPE_MAJOR_INTERPELLATION
      }[vtyp.downcase]
    end

    def self.parse_item(item)
      vtyp = item['VTyp']
      doctype = self.vtyp_to_paper_type vtyp
      legislative_term = item['VWp'].to_i
      reference = item['VNr']
      full_reference = "#{legislative_term}/#{reference}"
      title = nil
      published_at = nil
      is_answer = false

      originators = { people: [], parties: [] }
      answerers = { ministries: [] }
      skip = false

      [item['Dokument']].flatten.each do |document|
        if document['DokTyp'] == vtyp

          title = document['Titel'].try(:strip)
          next if title.nil?

          fundst = document['FundSt'].try(:strip)
          if !fundst.nil? && fundst.include?('Drs zurückgezogen')
            skip = true
            break
          end

          published_at = Date.parse document['AusgDat'] if !document['AusgDat'].nil? && published_at.nil?

          [document['urheber']].flatten.reject(&:nil?).each do |o|
            if o['istPerson'].to_i == 0
              originators[:parties] << o['name']
            else
              originators[:people] << [o['nam_zus'], o['vorname'], o['name']].reject(&:blank?).join(' ')
              originators[:parties] << o['fraktion']
            end
          end
        elsif document['DokTyp'] == 'Antw'

          is_answer = true

          published_at = Date.parse(document['AusgDat']) if !document['AusgDat'].nil?

          [document['urheber']].flatten.reject(&:nil?).each do |o|
            if o['istPerson'].to_i == 0
              answerers[:ministries] << o['vorname']
            end
          end
        end
      end

      return nil if skip

      paper = {
        legislative_term: legislative_term,
        reference: reference,
        full_reference: full_reference,
        doctype: doctype,
        title: title,
        # url -> DetailScraper
        published_at: published_at,
        is_answer: is_answer,
        originators: originators,
        answerers: answerers
      }
    end
  end
end