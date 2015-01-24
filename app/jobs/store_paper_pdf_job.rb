class StorePaperPDFJob < ActiveJob::Base
  queue_as :store

  def perform(paper)
    logger.info "Downloading PDF for Paper [#{paper.body.state} #{paper.full_reference}]"
    fail 'AppStorage: Bucket not available!' if AppStorage.bucket.nil?

    download_paper(paper)

    unless AppStorage.bucket.files.head(paper.path).nil?
      logger.info "PDF for Paper [#{paper.body.state} #{paper.full_reference}] already exists in Storage"
      return
    end

    file = AppStorage.bucket.files.new(key: paper.path, public: true, body: File.open(paper.local_path))
    file.save

    CountPageNumbersJob.perform_later(paper) if paper.page_count.blank?
    ExtractTextFromPaperJob.perform_later(paper) if paper.contents.blank?
  end

  def patron_session
    sess = Patron::Session.new
    sess.connect_timeout = 5
    sess.timeout = 60
    sess.headers['User-Agent'] = Rails.configuration.x.user_agent
    sess
  end

  def download_paper(paper)
    session = patron_session
    filepath = paper.local_path
    folder = filepath.dirname
    FileUtils.mkdir_p folder

    resp = session.get(paper.url)
    if resp.status != 200
      logger.warn "Download failed for Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    f = File.open(filepath, 'wb')
    begin
      f.write(resp.body)
    rescue
      logger.warn "Cannot write file for Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    ensure
      f.close if f
    end

    return unless paper.downloaded_at.nil?
    paper.downloaded_at = DateTime.now
    paper.save
  end
end