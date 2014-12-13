class BayernPDFExtractor
  def initialize(paper)
    @contents = paper.contents
  end

  def extract
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
end