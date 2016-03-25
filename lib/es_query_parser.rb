class EsQueryParser
  def self.convert_date_range(text)
    r = parse_range(text)
    return nil if r.nil?

    convert_date = ->(value) do
      if value.size == 4 && value.to_i.to_s == value
        # looks like a year
        value
      else
        # everything else
        Date.parse(value).to_s
      end
    end

    if r[:type] == :equals
      return convert_date.call(r[:value])
    elsif r[:type] == :range
      r[:value] = r[:value].map(&convert_date)
      return return_range(r)
    end

    h = {}
    h[r[:type]] = convert_date.call(r[:value])
    h
  rescue
    nil
  end

  def self.convert_range(text)
    r = parse_range(text)
    return nil if r.nil?

    if r[:type] == :equals
      return Integer(r[:value])
    elsif r[:type] == :range
      r[:value] = r[:value].map { |v| Integer(v) }
      return return_range(r)
    end

    h = {}
    h[r[:type]] = r[:value].to_i
    h
  rescue
    nil
  end

  def self.return_range(r)
    if r[:range] == :inclusive
      { gte: r[:value].first, lte: r[:value].last }
    elsif r[:range] == :exclusive
      { gt: r[:value].first, lt: r[:value].last }
    end
  end

  def self.parse_range(text)
    text = text.to_s.strip
    return nil if text.blank?

    if text.start_with? '>='
      { type: :gte, value: text[2..-1] }
    elsif text.start_with? '<='
      { type: :lte, value: text[2..-1] }
    elsif text.start_with? '>'
      { type: :gt, value: text[1..-1] }
    elsif text.start_with? '<'
      { type: :lt, value: text[1..-1] }
    elsif text.start_with?('[') && text.include?(' ') && text.end_with?(']')
      parts = text.gsub(/\A\[(.+)\]\z/, "\\1").split(' ')
      { type: :range, range: :inclusive, value: [parts.first, parts.last] }
    elsif text.start_with?('{') && text.include?(' ') && text.end_with?('}')
      parts = text.gsub(/\A\{(.+)\}\z/, "\\1").split(' ')
      { type: :range, range: :exclusive, value: [parts.first, parts.last] }
    else
      { type: :equals, value: text }
    end
  end

  def self.map_simple_query_string_word(term, map = nil)
    map = { 'oder' => '|', 'or' => '|' } if map.nil?
    map.each do |word, replacement|
      term.gsub!(/\s+#{word}\s+(?=(?:[^"\\]*(?:\\.|"(?:[^"\\]*\\.)*[^"\\]*"))*[^"]*$)/i, " #{replacement} ")
    end
    term
  end
end