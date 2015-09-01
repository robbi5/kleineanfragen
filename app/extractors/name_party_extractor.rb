class NamePartyExtractor
  NAME_BRACKET_PARTY = :nbp
  NAME_PARTY_COMMA = :npc
  REVERSED_NAME_PARTY = :rnp

  def initialize(text, format = NAME_BRACKET_PARTY)
    @text = text
    @format = format
  end

  def extract
    case @format
    when NAME_BRACKET_PARTY then extract_nbp
    when NAME_PARTY_COMMA then extract_npc
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
        parties << party.sub(/Fraktion\s+(?:der\s+)?/, '')
      end
      if !sa.blank? && parties.blank? && sa.last.include?(' ')
        # Space seperated party
        last = sa.pop
        parts = last.split(' ').reject { |p| p.include? 'u.a.' }
        parties << parts.pop if parts.size > 1
        sa << parts.join(' ')
      end
      sa.reject!(&:blank?)
      people << sa.reverse.join(' ') unless sa.size == 0
    end

    { people: people, parties: parties.uniq }
  end

  def extract_npc
    people = []
    parties = []
    pairs = @text.gsub("\n", ' ').gsub(' und', ', ').split(',').map(&:strip)

    pairs.each do |line|
      m = line.match(/\A(.+?)(?:\s([A-Z][a-zA-Z]{2}|[A-Z]{2,}[[:alnum:]\s\/]+))?\z/)
      next if m.nil?
      person = m[1].gsub(/\p{Z}+/, ' ').strip
      people << person unless person.blank?
      parties << m[2].gsub(/\p{Z}+/, ' ').strip unless m[2].nil?
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
      parties << m[2].gsub(/\p{Z}+/, ' ').strip.sub(/^Fraktion\s+(?:der\s+)?/, '') unless m[2].nil?
    end

    { people: people, parties: parties.uniq }
  end
end