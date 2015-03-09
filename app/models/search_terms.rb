# Search term parser from https://gist.github.com/1477730
# Modified to allow periods (and other non-letter chars) in unquoted field values
# and field names.
#
# Helper class to help parse out more advanced search terms
# from a form query
#
# Note: all hash keys are downcased, so ID:10 == {'id' => 10}
#       you can also access all keys with methods e.g.: terms.id = terms['id'] = 10
#       this doesn't work with query as thats reserved for the left-over pieces
#
# Usage:
#   terms = SearchTerms.new('id:10 search terms here')
#   => @query="search terms here", @parts={"id"=>"10"}
#   => terms.query = 'search terms here'
#   => terms['id'] = 10
#
#   terms = SearchTerms.new('name:"support for spaces" state:pa')
#   => @query="", @parts={"name"=>"support for spaces", "state"=>"pa"}
#   => terms.query = ''
#   => terms['name'] = 'support for spaces'
#   => terms.name = 'support for spaces'
#
#   terms = SearchTerms.new('state:pa,nj,ca')
#   => @query="", @parts={"state"=>["pa","nj","ca"]}
#
#   terms = SearchTerms.new('state:pa,nj,ca', false)
#   => @query="", @parts={"state"=>"pa,nj,c"}
#
# Useful to drive custom logic in controllers
class SearchTerms
  attr_reader :query, :parts

  # regex scanner for the parser
  SCANNER = %r{
    (?:                       # get key or normal query parts
      (
        [^\:\"\s]+            # no spaces, no quotes, no delimiter
        |                     # -or-
        (?:"(?:[^\"])*")      # match any quoted values
      )
    )
    (?:                       # check if it has a value attached
      :                       # find the value delimiter
      (
        [\w,\-]+              # match any word-like values
        |                     # -or-
        (?:"(?:.+|[^\"])*")   # match any quoted values
      )
    )?
  }x

  # query:: this is what you want tokenized
  # split:: if you'd like to split values on "," then pass true
  def initialize(query, whitelist = nil, split = true)
    @query = query
    @parts = {}
    @whitelist = whitelist
    @split = split
    parse_query!
  end

  def [](key)
    @parts[key]
  end

  private

  def parse_query!
    tmp = []

    @query.scan(SCANNER).map do |key, value|
      if value.nil?
        tmp << key
      elsif !@whitelist.nil? && !@whitelist.include?(key.to_s.downcase)
        tmp << "#{key}:#{value}"
      else
        key.downcase!
        @parts[key] = clean_value(value)
        define_metaclass_method(key) { @parts[key] } unless key == 'query'
      end
    end

    @query = tmp.join(' ')
  end

  def clean_value(value)
    return value.tr('"', '') if value.include?('"')
    return value.split(',') if @split && value.include?(',')
    return true if value == 'true'
    return false if value == 'false'
    return value.to_i if value =~ /^[1-9][0-9]*$/
    value
  end

  def define_metaclass_method(method, &block)
    (class << self; self; end).send :define_method, method, &block
  end
end