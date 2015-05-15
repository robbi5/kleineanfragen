class StorePaperPDFJob < PaperJob
  include ActiveJob::Retry

  queue_as :store

  variable_retry delays: [5, 15, 30, 90],
                 retryable_exceptions: [Patron::TimeoutError]

  def perform(paper, options = {})
    options.reverse_merge!(force: false)

    logger.info "Downloading PDF for Paper [#{paper.body.state} #{paper.full_reference}]"
    fail 'AppStorage: Bucket not available!' if AppStorage.bucket.nil?

    if !AppStorage.bucket.files.head(paper.path).nil? && !options[:force]
      logger.info "PDF for Paper [#{paper.body.state} #{paper.full_reference}] already exists in Storage"
      return
    end

    ret = download_paper(paper)
    fail "Downloading Paper [#{paper.body.state} #{paper.full_reference}] failed" unless ret

    file = AppStorage.bucket.files.new(key: paper.path, public: true, body: File.open(paper.local_path))
    file.save

    ThumbnailFirstPageJob.perform_later(paper, force: options[:force]) if paper.thumbnail_url.blank? || options[:force]
    CountPageNumbersJob.perform_later(paper) if paper.page_count.blank? || options[:force]
    ExtractTextFromPaperJob.perform_later(paper) if paper.contents.blank? || options[:force]
    ExtractLastModifiedFromPaperJob.perform_later(paper) if paper.pdf_last_modified.blank?
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

    content_type = content_type(resp)

    if paper.body.state == 'HH' && content_type != 'application/pdf'
      js = resp.body.match(/location\.replace\(['"](.+)['"]\)/)
      fail "Could not extract PDF path for Hamburg Paper [#{paper.body.state} #{paper.full_reference}]" if js.nil?
      url = Addressable::URI.parse(paper.url).join(js[1]).normalize.to_s
      resp = session.get(url)
      if resp.status != 200
        logger.warn "Download failed with status #{resp.status} for Paper [#{paper.body.state} #{paper.full_reference}]"
        return false
      end
      content_type = content_type(resp)
    end

    if content_type != 'application/pdf'
      logger.warn "File for Paper [#{paper.body.state} #{paper.full_reference}] is not a PDF: #{content_type}"
      return false
    end

    last_modified = resp.headers.try(:[], 'Last-Modified')

    f = File.open(filepath, 'wb')
    begin
      f.write(resp.body)
    rescue
      logger.warn "Cannot write file for Paper [#{paper.body.state} #{paper.full_reference}]"
      return false
    ensure
      f.close if f
    end

    paper.pdf_last_modified = DateTime.parse(last_modified) unless last_modified.blank?
    paper.downloaded_at = DateTime.now if paper.downloaded_at.nil?
    paper.save
  end

  def content_type(response)
    content_type = response.headers['Content-Type']
    if content_type.is_a? Array
      content_type.last
    else
      content_type
    end
  end
end