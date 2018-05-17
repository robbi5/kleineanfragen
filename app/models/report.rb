class Report < Hash
  def initialize(created_at = nil)
    send(:[]=, :created_at, created_at.to_s)
  end
end