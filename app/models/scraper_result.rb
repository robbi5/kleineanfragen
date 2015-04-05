class ScraperResult < ActiveRecord::Base
  belongs_to :body

  def status
    if queued?
      'waiting'
    elsif success?
      'success'
    elsif running?
      'running'
    else
      'failure'
    end
  end

  def queued?
    !created_at.nil? && started_at.nil? && stopped_at.nil?
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
    super(*options).merge(status: status, running: running?, id: to_param)
  end
end
