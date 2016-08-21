class EmailProcessor
  def initialize(email)
    @email = email
  end

  #@email.from[:email]
  #@email.subject
  #@email.body
  def process
    logger.info @email.inspect

    if @email.from[:email].ends_with? '@parlament-berlin.de'
      berlin = Body.find_by_state('BE')
      InstantImportNewPapersJob.perform_later(berlin, berlin.legislative_terms.first.term)
    end
  end

  private

  def logger
    @logger ||= Rails.logger
  end
end