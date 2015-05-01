class NamePartyExtractor
  NAME_BRACKET_PARTY = :nbp
  REVERSED_NAME_PARTY = :rnp

  def initialize(text, format = NAME_BRACKET_PARTY)
    @text = text
    @format = format
  end

  def extract
    case @format
    when NAME_BRACKET_PARTY then extract_nbp
    when REVERSED_NAME_PARTY then extract_rnp
    else fail 'Unknown format'
    end
  end

  def extract_rnp
    people = []
    parties = []

    @text.split(';').map do |s|
      sa = s.strip.split(',').map(&:strip)
      unless sa.size == 2 # party missing
        party = sa.pop
        parties << party unless party.include?('Fraktion')
      end
      if sa.last.include?(' ')
        # Space seperated party
        last = sa.pop
        parts = last.split(' ').reject {|p| p.include? 'u.a.' }
        parties << parts.pop if parts.size > 1
        sa << parts.join(' ')
      end
      people << sa.reverse.join(' ')
    end

    { people: people, parties: parties.uniq }
  end

  def extract_nbp
    people = []
    parties = []
    pairs = @text.gsub("\n", '').gsub(' und', ', ').split(',').map(&:strip)

    pairs.each do |line|
      m = line.match(/(.+)\s\((.+)\)/)
      m = ['', line.strip] if m.nil?
      person = m[1].gsub(/\p{Z}+/, ' ').strip
      people << person unless person.blank?
      parties << m[2].gsub(/\p{Z}+/, ' ').strip.sub(/^Fraktion\s+/, '') unless m[2].nil?
    end

    { people: people, parties: parties.uniq }
  end
end