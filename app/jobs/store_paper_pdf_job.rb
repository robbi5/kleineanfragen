class StorePaperPDFJob < ActiveJob::Base
  queue_as :store

  def perform(paper)
    Rails.logger.info "Downloading PDF for Paper [#{paper.body.state} #{paper.full_reference}]"

    download_paper(paper)

    unless FogStorageBucket.files.head(paper.path).nil?
      Rails.logger.info "PDF for Paper [#{paper.body.state} #{paper.full_reference}] already exists in Storage"
      return
    end

    file = FogStorageBucket.files.new(key: paper.path, public: true, body: File.open(paper.local_path))
    file.save

    CountPageNumbersJob.perform_later(paper) if paper.page_count.blank?
    ExtractTextFromPaperJob.perform_later(paper) if paper.contents.blank?
  end

  def patron_session
    sess = Patron::Session.new
    sess.timeout = 15
    sess.headers['User-Agent'] = Rails.application.config.user_agent
    sess
  end

  def download_paper(paper)
    session = patron_session
    filepath = paper.local_path
    folder = filepath.dirname
    FileUtils.mkdir_p folder

    resp = session.get(paper.url)
    if resp.status != 200
      Rails.logger.debug "Download failed for Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    f = File.open(filepath, 'wb')
    begin
      f.write(resp.body)
    rescue
      Rails.logger.debug "Cannot write file for Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    ensure
      f.close if f
    end

    return unless paper.downloaded_at.nil?
    paper.downloaded_at = DateTime.now
    paper.save
  end
end