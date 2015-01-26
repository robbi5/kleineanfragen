class BundestagPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  ORIGINATORS = /der Abgeordneten (.+?)(?:,\s+weiterer\s+Abgeordneter)?\s+und\s+der\s+Fraktion\s+(?:der\s+)?(.{0,30}?)\.?\n/m

  def extract_originators
    return nil if @contents.nil?
    people = []
    parties = []

    @contents.scan(ORIGINATORS).each do |m|
      m[0].split(',').each do |person|
        person = person.gsub(/\p{Z}/, ' ')
                 .gsub("\n", ' ')
                 .gsub(/\s+/, ' ')
                 .strip
                 .sub(/^der\s/, '')
                 .sub(/\s\(.+\)$/, '') # remove city
                 .sub(/^Kleine\s+Anfrage\s+der\s+Abgeordneten\s+/, '') # duplicate prefix
        people << person unless person.blank? || person == 'weiterer Abgeordneter'
      end
      parties << m[1].gsub("\n", ' ').strip.sub(/^der\s/, '').sub(/\.$/, '')
    end

    { people: people, parties: parties }
  end
end