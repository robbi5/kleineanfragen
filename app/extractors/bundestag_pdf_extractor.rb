class BundestagPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  def extract_originators
    return nil if @contents.nil?
    people = []
    parties = []
    m = @contents.match(/auf die Kleine Anfrage der Abgeordneten\s(.+)\sund der Fraktion\s(.{3,30})\p{Z}*\n/m)

    m[1].split(',').each do |person|
      person = person.gsub(/\p{Z}/, ' ').gsub("\n", ' ').gsub(/\s+/, ' ').strip
      people << person unless person == 'weiterer Abgeordneter'
    end
    parties << m[2].gsub("\n", ' ').strip.sub(/\.$/, '')

    { people: people, parties: parties }
  end
end