require 'fileutils'

class FetchPapersJob

  def self.perform(*params)
    raise 'State is not defined' unless defined? @state
    @body = Body.find_by(state: @state)
    raise 'Required body "' + @state + '" not found' if @body.nil?
  end

  def self.download_papers
    @papers = Paper.where(body: @body, downloaded_at: nil).limit(50)

    @data_folder = Rails.application.config.paper_storage
    @papers.each do |paper|
      folder = @data_folder.join(@body.folder_name, paper.legislative_term.to_s)
      FileUtils.mkdir_p folder
      filename = paper.reference.to_s + '.pdf'
      path = folder.join(filename)
      `wget -O "#{path}" "#{paper.url}"` # FIXME: use ruby
      if $?.to_i == 0
        paper.downloaded_at = DateTime.now
        paper.save
      end
    end
  end

  def self.extract_text_from_papers
    @papers = Paper.where(body: @body, contents: nil).where.not(downloaded_at: nil)

    @papers.each do |paper|
      text = paper.extract_text
      paper.contents = text
      paper.save
    end
  end

  def self.count_page_numbers
    @papers = Paper.where(body: @body, page_count: nil).where.not(downloaded_at: nil)

    @papers.each do |paper|
      count = paper.extract_page_count
      paper.page_count = count
      paper.save
    end
  end
end