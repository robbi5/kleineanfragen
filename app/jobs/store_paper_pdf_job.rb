class StorePaperPDFJob < ActiveJob::Base
  queue_as :store

  def perform(paper, force: false)
    logger.info "Downloading PDF for Paper [#{paper.body.state} #{paper.full_reference}]"
    fail 'AppStorage: Bucket not available!' if AppStorage.bucket.nil?

    ret = download_paper(paper)

    if !ret
      fail "Downloading Paper [#{paper.body.state} #{paper.full_reference}] failed"
    end

    if !AppStorage.bucket.files.head(paper.path).nil? && !force
      logger.info "PDF for Paper [#{paper.body.state} #{paper.full_reference}] already exists in Storage"
      return
    end

    file = AppStorage.bucket.files.new(key: paper.path, public: true, body: File.open(paper.local_path))
    file.save

    ThumbnailFirstPageJob.perform_later(paper) if paper.thumbnail_url.blank?
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
      logger.warn "Download failed with status #{resp.status} for Paper [#{paper.body.state} #{paper.full_reference}]"
      return false
    end

    # FIXME: add support for weird redirection things like HH uses

    content_type = resp.headers['Content-Type']
    content_type = content_type.last if content_type.is_a? Array

    if content_type != 'application/pdf'
      logger.warn "File for Paper [#{paper.body.state} #{paper.full_reference}] is not a PDF: #{content_type}"
      return false
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

    return true unless paper.downloaded_at.nil?
    paper.downloaded_at = DateTime.now
    paper.save
  end
end