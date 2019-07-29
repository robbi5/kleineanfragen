class ClassifiedRecognizer
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

    # generic
    match(/Antwort(?:en)?.{1,35}als.{1,20}Verschlusssache.{1,20}eingestuft/m, :verschlusssache)

    # ST: note in footer
    # SH: note in footer
    match(/Einsichtnahme\s+des\s+vertraulichen\s+Teils\s+.+?\s+Geheimschutzstelle/m, :st_geheimschutzstelle)

    # BT: note in text
    match(/Geheimschutzstelle\s+des\s+(Deutschen\s+)?Bundestages/m, :bt_geheimschutzstelle)

    # SH: note in text
    match(/Beantwortung.+erfolgt.+als.+Verschlusssache/m, :sh_verschlussache)

    # SN: note in text
    match(/Beantwortung.+der.+Frage.+an.+die.+Geheimschutzstelle/m, :sn_geheimschutzstelle)

    {
      probability: @probability,
      groups: @groups.uniq,
      matches: @matches
    }
  end

  private

  def match(regex, group, factor: 1)
    return if @skip.include?(group)

    m = nil
    begin
      m = SafeRegexp.execute(text, :scan, regex, timeout: 5)
    rescue SafeRegexp::RegexpTimeout
      m = nil
    end
    return if m.blank?

    @probability += factor * m.size
    @groups << group
    @matches << m if debug?
  rescue
    # ignore
  end

  def match_each(regex, group, factor: 1, &block)
    return if @skip.include?(group)

    begin
      m = SafeRegexp.execute(text, :scan, regex, timeout: 5)
    rescue SafeRegexp::RegexpTimeout
      m = nil
    end
    return if m.blank?

    m.each do |match|
      ret = yield match
      next if !ret

      @probability += factor
      @groups << group
      @matches << match if debug?
    end
  end
end