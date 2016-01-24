class EsQueryParser
  def self.convert_date_range(text)
    r = parse_range(text)
    return nil if r.nil?

    v = nil
    if r[:value].size == 4 && r[:value].to_i.to_s == r[:value]
      # looks like a year
      v = r[:value]
    else
      # everything else
      begin
        v = Date.parse(r[:value]).to_s
      rescue
        return nil
      end
    end
    return nil if v.nil?

    return v if r[:type] == :equals

    h = {}
    h[r[:type]] = v
    h
  end

  def self.convert_range(text)
    r = parse_range(text)
    return nil if r.nil?

    if r[:type] == :equals
      begin
        Integer(text)
      rescue
        nil
      end
    else
      h = {}
      h[r[:type]] = r[:value].to_i
      h
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
    else
      { type: :equals, value: text }
    end
  end
end