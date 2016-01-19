class EsQueryParser
  def self.convert_range(text)
    text = text.to_s.strip
    return nil if text.blank?

    if text.start_with? '>='
      { gte: text[2..-1].to_i }
    elsif text.start_with? '<='
      { lte: text[2..-1].to_i }
    elsif text.start_with? '>'
      { gt: text[1..-1].to_i }
    elsif text.start_with? '<'
      { lt: text[1..-1].to_i }
    else
      begin
        Integer(text)
      rescue
        nil
      end
    end
  end
end