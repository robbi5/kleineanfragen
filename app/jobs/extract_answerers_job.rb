class ExtractAnswerersJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    # FIXME: generic?
    return unless paper.body.state == 'BY'
    Rails.logger.info "Extracting Answerers from Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    answerers = BayernPDFExtractor.new(paper).extract_answerers
    if answerers.nil?
      Rails.logger.warn "No Answerers found in Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    unless answerers[:ministries].blank?
      # write ministry
      answerers[:ministries].each do |ministry|
        ministry = normalize(ministry, 'ministries', paper.body)
        Rails.logger.debug "+ Ministry: #{ministry}"
        min = Ministry
              .where(body: paper.body)
              .where('lower(name) = ?', ministry.mb_chars.downcase.to_s)
              .first_or_create(body: paper.body, name: ministry)
        unless paper.answerer_ministries.include? min
          paper.answerer_ministries << min
          paper.save
        end
      end
    else
      Rails.logger.warn "No Ministries found in Paper [#{paper.body.state} #{paper.full_reference}]"
    end
  end

  def normalize(name, prefix, body = nil)
    return name if Rails.configuration.x.nomenklatura_api_key.blank?
    Nomenklatura::Dataset.new("ka-#{prefix}" + (!body.nil? ? "-#{body.state.downcase}" : '')).lookup(name)
  end
end