require 'fileutils'

class FetchPapersJob

  def self.perform(*params)
    raise 'State is not defined' unless defined? @state
    @body = Body.find_by(state: @state)
    raise 'Required body "' + @state + '" not found' if @body.nil?
  end

  def self.download_papers
    @papers = Paper.where(body: @body, downloaded_at: nil).limit(50)

    @data_folder = Rails.root.join('data')
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

end