class FillPaperPDFLastModifiedJob < PaperJob
  queue_as :meta

  # Paper.where(pdf_last_modified: nil).each {|p| FillPaperPDFLastModifiedJob.perform_later(p) }
  def perform(paper)
    session = patron_session
    url = paper.url
    resp = nil

    loop do
      resp = session.head(url)
      if resp.status > 300 && resp.status < 400
        url = Addressable::URI.parse(url).join(resp.headers['Location']).normalize.to_s
        next
      end
      fail "HEAD failed with status #{resp.status} for Paper [#{paper.body.state} #{paper.full_reference}]" if resp.status != 200
      break
    end

    content_type = resp.headers['Content-Type']
    content_type = content_type.last if content_type.is_a? Array
    fail "File for Paper [#{paper.body.state} #{paper.full_reference}] is not a PDF: #{content_type}" if content_type != 'application/pdf'

    last_modified = resp.headers.try(:[], 'Last-Modified')
    fail "Last-Modified-Header does not exist for Paper [#{paper.body.state} #{paper.full_reference}]" if last_modified.blank?

    paper.pdf_last_modified = DateTime.parse(last_modified)
    paper.save
  end

  def patron_session
    sess = Patron::Session.new
    sess.connect_timeout = 5
    sess.timeout = 60
    sess.headers['User-Agent'] = Rails.configuration.x.user_agent
    sess
  end
end