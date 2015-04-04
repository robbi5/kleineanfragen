class ScraperResult < ActiveRecord::Base
  belongs_to :body

  def css_class
    if success?
      'success'
    elsif running?
      'running'
    else
      'failure'
    end
  end

  def running?
    !started_at.nil? && stopped_at.nil?
  end

  def to_param
    self.class.hashids.encode(id)
  end

  def self.find_by_hash(hash)
    id = hashids.decode(hash).first
    fail 'Invalid id' if id.nil?
    find(id)
  end

  def self.hashids
    Hashids.new('ScraperResult', 5)
  end

  def as_json(*options)
    super(*options).merge(status: css_class, running: running?, id: to_param)
  end
end
