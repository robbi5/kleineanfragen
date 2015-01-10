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
end