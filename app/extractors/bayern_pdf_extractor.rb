class BayernPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  def extract_originators
    return nil if @contents.nil?
    people = []
    parties = []
    [
      /Abgeordneten ([\D\n]+?)\s(\p{Lu}[\p{Lu} \d\/\n]+)\b/m,
      /Abgeordneten ([\D\n]+?)\s(\p{Lu}[\p{Lu} \d\/]+)\b/m,
      /Abgeordneten ([\D\n]+?)\p{Zs}(\p{Lu}[\p{Lu} \d\/]+)\b/m,
      /Abgeordneten ([\D\n]+?)\n(\p{Lu}[\p{Ll}\p{Lu} \d\/]+)\b/m,
      # /Abgeordneten ([\D\n]+?)\s([[:upper:] \d\/]+)/m
    ].each do |regex|
      m = @contents.match(regex)
      next unless m

      person = m[1].gsub(/\p{Zs}/, ' ').gsub("\n", '').gsub(' und', ', ')
      if person.include?(',')
        people.concat person.split(',').map(&:strip)
      else
        people << person
      end
      parties << m[2].gsub("\n", ' ').strip

      # only one regex must match
      break
    end
    { people: people, parties: parties }
  end

  def extract_answerers
    return nil if @contents.nil?
    ministries = []

    # FIXME add people
    # [dD]e[rs]\s([\p{L}\s\,]+)\s+vom
    # Antwort\nder Staatsministerin für Gesundheit und Pflege\nvom 20.08.2014
    # Antwort\nDes Leiters der Bayerischen Staatskanzlei Staatsministerin für Bundesangelegenheiten und Sonderaufgaben\n\nvom 21.08.2014

    # Antwort\ndes Staatsministeriums des Innern, für Bau und Verkehr\nvom 10.10.2014
    m = @contents.match(/Antwort\ndes (Staatsministeriums?\s[\p{L}\s\,\-]+)\s+vom/m)
    if m
      ministry = m[1].gsub("\n", '')
      ministry.gsub!(/^Staatsministeriums/, 'Staatsministerium') # remove Genitiv
      ministries << ministry
    end

    { ministries: ministries }
  end
end