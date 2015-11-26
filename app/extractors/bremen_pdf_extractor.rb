class BremenPDFExtractor
  def initialize(paper)
    @contents = paper.contents
    @doctype = paper.doctype
    @title = paper.title
  end

  ORIGINATORS = /\d+.+[\?\.\\](?:\n\n(.+?)\s+und\s+Fraktion\s+[^\n]+)(?:\n\n(.+?)\s+und\s+Fraktion\s+[^\n]+)*.+(?:Antwort\s+des\s+Senats|Der\s+Senat\s+beantwortet)/m
  FACTIONS = /Antwort\s+des\s+Senats\s+auf\s+die\s......\s+Anfrage der(.*)/m

  def extract_originators
    return nil if @contents.nil? || @doctype == Paper::DOCTYPE_MAJOR_INTERPELLATION
    people = []
    parties = []
    if @contents.include?('und Fraktion')
      shortened_title = @title[0..30]
      faction_match = @contents.match(FACTIONS)
      unless faction_match.nil? || !faction_match[1].include?(shortened_title)
        factions = faction_match[1]
        factions = factions[0..(factions.index(shortened_title) - 1)].gsub("\n", ' ')
        factions = NamePartyExtractor.new(factions, NamePartyExtractor::FACTION).extract
        parties.concat factions[:parties]
      end
    end

    m = @contents.match(ORIGINATORS)
    if !m.nil?
      originators = m[1].split(',')
      originators.concat m[2].split(',') unless m[2].nil?
      originators.each do |person|
        person = person.gsub(/\p{Z}/, ' ').gsub("\n", ' ').gsub(/\s+/, ' ').gsub(/\p{Other}/, '').strip
        people << person unless person.blank?
      end
    end
    { people: people, parties: parties }
  end
end
