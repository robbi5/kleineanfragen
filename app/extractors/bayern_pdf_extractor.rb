class BayernPDFExtractor

  def initialize(paper)
    @contents = paper.contents
  end

  def extract
    people = []
    party = ""
    #if m = @contents.match(/de[rs](?:\/des)?\s?Abgeordneten ([\D\n]+?)\s(\p{Lu}[\p{Lu} \d\/]+)\b/m)
    if m = @contents.match(/Abgeordneten ([\D\n]+?)\s([[:upper:] \d\/]+)/m)
      person = m[1]
      person = person.gsub("\n", '').gsub(' und', ', ')
      if person.include?(',')
        people = person.split(',').map { |n| n.strip }
      else
        people = [person]
      end
      party = m[2]
    end
    {people: people, party: party}
  end
end