class ScraperResult < ActiveRecord::Base
  belongs_to :body

  def css_class
    success? ? 'ok' : 'failed'
  end
end
