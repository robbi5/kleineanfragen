class PDFExtractor

  MULTIPLE_RELATED_MINISTRIES = /((?:Staats)?[mM]inisterium.*?)\s?(?:(?:,|,\s+sowie|sowie|und\s+mit|und|mit)\s+dem\s+((?:Staats)?[mM]inisterium.+))+$/m

  def self.split_ministries(text)
    ministries = text.match(MULTIPLE_RELATED_MINISTRIES)
    return [text] unless ministries
    results = []
    x = ministries.captures
    results << x.shift
    x.each do |related_ministry|
      results << split_ministries(related_ministry)
    end
    results.flatten
  end
end