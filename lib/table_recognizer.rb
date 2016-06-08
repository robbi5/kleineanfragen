class TableRecognizer
  attr_accessor :skip
  attr_reader :text
  attr_writer :debug

  def initialize(text, debug: false, skip: nil)
    @text = text
    @debug = debug
    @skip = skip || []
  end

  def debug?
    @debug
  end

  def recognize
    throw 'No text set' if @text.nil?

    @probability = 0.0
    @groups = []
    @matches = []

    # Hint 1: "<synonym für nachfolgende> Tabelle"
    match(/(?:[bB]eiliegende|beigefügte|anliegende|[Ff]olgende|vorstehende|nachstehende|unten stehende)[nr]? Tabelle/, :synonym)

    # Hint 2: "Tabelle \d zeigt", "siehe Tabelle \d", "siehe Tabelle in Anlage"
    match(/Tabelle \d zeigt/, :table_shows)
    match(/siehe Tabelle (?:\d|in Anlage)/, :table_shows)

    # Hint 3: (Tabelle 1) ... (Tabelle 2)
    match(/\(Tabelle \d\)/, :table_parenthesized)

    # Hint 4: "die Tabellen 1 bis 4"
    match(/[Dd]ie Tabellen \d bis \d/, :tables_num)

    # Hint 5: "\nTabelle 2:\n"
    match(/\nTabelle \d:\n/, :table_num)

    begin
      Timeout::timeout(5) do
        # Hint 6: \d\n\d\n\d\n...
        #m = text.scan(/\p{Zs}(\d[\p{Zs}\d]+\n\d[\p{Zs}\d]+)+/m)
        match(/(\d[\p{Zs}\d]+\n\d[\p{Zs}\d]+)+/m, :looks_like_table_newlines, factor: 0.5) # TODO: lookahead/lookbehind?
      end
    rescue => e
      # ignore failure
    end

    # Hint 7: Anlage 3 Tabelle 1, Anlage / Tabelle 1
    match(/Anlage\s+[\d\/]+\s+Tabelle\s+\d+/m, :attachment_table)

    begin
      Timeout::timeout(5) do
        # Hint 8: "\nAAA 10,1 10,2 10,3\nBBB 20 21,1 -1.022,2"
        match_each(/\n([\p{Zs}\S]+?\p{Zs}+(\-?(?>(?:\d{1,3}(?>(?:\.\d{3}))*(?>(?:,\d+)?|\d*\.?\d+))\p{Zs}*)+))\n/m, :looks_like_table_values, factor: 0.5) do |match|
          match.first.strip != match.second.strip &&
            !match.first.strip.start_with?('vom') &&
            !match.first.match('\d{2}\.\d{2}\.\d{4}') &&
            !match.first.match('Seite\s+\d+\s+von\s+\d+') &&
            !match.first.match('(?:Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember)\s+\d{4}\s*\z') &&
            !match.first.match('(?:Str\.\s\d+|-Platz\s\d+)') &&
            !match.first.strip.match('\A(?:[0-9]|[MCDXLVI])+\.\s+[^\n]+\s\d+\s*\z')
        end
      end
    rescue => e
      # ignore failure
    end

    {
      probability: @probability,
      groups: @groups.uniq,
      matches: @matches
    }
  end

  private

  def match(regex, group, factor: 1)
    return if @skip.include?(group)
    m = text.scan(regex)
    return if m.blank?
    @probability += factor * m.size
    @groups << group
    @matches << m if debug?
  end

  def match_each(regex, group, factor: 1, &block)
    return if @skip.include?(group)
    m = text.scan(regex)
    return if m.blank?
    m.each do |match|
      ret = yield match
      if ret
        @probability += factor
        @groups << group
        @matches << match if debug?
      end
    end
  end
end